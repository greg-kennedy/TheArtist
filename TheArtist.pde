// The Artist
// Greg Kennedy 2022

////////////////////////////////////////////////////////////////////
// knobs

// source image tweaks
// palettize
final boolean paletteEnable = false;
final int paletteDepth = 6;
// grayscale
final boolean grayscale = false;

// edge detect tweaks
//  blur amount
final int blurIterations = 3;
// type (0 = box, 1 = gaussian)
final int blurType = 1;

// output image tweaks
// alpha blend (0 = off, 1 = half, 2 = simple, 3 = reverse, 4 = gamma)
final int alphaBlend = 2;
// max detail (255 max)
final int limit = 255;
// shape (0 = circle, 1 = line, 2 = box)
final int shape = 0;
// for line, start-angle and variance define the direction of sketching
//  use radians :)
final float angle = 0;
final float variance = PI / 9;

////////////////////////////////////////////////////////////////////
// globals
PImage img;
PImage edgeImg;

////////////////////////////////////////////////////////////////////
// Edge Detection
PImage edgeDetect(final PImage img) {
  
  // prep source image
  img.loadPixels();
  
  float[][] src = new float[img.height][img.width];
  
  // make gray
  for (int y = 0, s = 0; y < img.height; y ++)
  {
    for (int x = 0; x < img.width; x ++, s ++)
    {
      src[y][x] =.299 * red(img.pixels[s]) + .587 * green(img.pixels[s]) + .114 * blue(img.pixels[s]);
    }
  }

  // blur
  for (int iterations = 0; iterations < blurIterations; iterations ++) {
    float[][] blur = new float[img.height][img.width];
    for (int y = 1; y < img.height - 1; y ++)
    {
      for (int x = 1; x < img.width - 1; x ++)
      {
        if (blurType == 0) {
          // box
          blur[y][x] = (src[y-1][x-1] + src[y-1][x] + src[y-1][x+1] +
                        src[y][x-1] + src[y][x] + src[y][x+1] +
                        src[y+1][x-1] + src[y+1][x] + src[y+1][x+1]) / 9.0;
        } else {
          // gaussian
          blur[y][x] = (src[y-1][x-1] + 2 * src[y-1][x] + src[y-1][x+1] +
                        2 * src[y][x-1] + 4 * src[y][x] + 2 * src[y][x+1] +
                        src[y+1][x-1] + 2 * src[y+1][x] + src[y+1][x+1]) / 16.0;
        }
      }
    }
    
    // fix borders (copy)
    for (int y = 0; y < img.height; y ++) {
      blur[y][0] = blur[y][1];
      blur[y][img.width - 1] = blur[y][img.width - 2];
    }
    for (int x = 0; x < img.width; x ++) {
      blur[0][x] = blur[1][x];
      blur[img.height - 1][x] = blur[img.height - 2][x];
    }
    
    src = blur;
  }

  // edge detect (Sobel)
  float[][] edges = new float[img.height][img.width];
  
  for (int y = 1; y < img.height - 1; y ++)
  {
    for (int x = 1; x < img.width - 1; x ++)
    {
      edges[y][x] = sqrt(
        pow( (src[y-1][x-1] + 2 * src[y][x-1] + src[y+1][x-1]) - 
             (src[y-1][x+1] + 2 * src[y][x+1] + src[y+1][x+1]), 2) +
        pow( (src[y-1][x-1] + 2 * src[y-1][x] + src[y-1][x+1]) - 
             (src[y+1][x-1] + 2 * src[y+1][x] + src[y+1][x+1]), 2)
      );
    }
  }

  // fix borders (copy)
  for (int y = 0; y < img.height; y ++) {
    edges[y][0] = edges[y][1];
    edges[y][img.width - 1] = edges[y][img.width - 2];
  }
  for (int x = 0; x < img.width; x ++) {
    edges[0][x] = edges[1][x];
    edges[img.height - 1][x] = edges[img.height - 2][x];
  }

  // equalize histogram
  float[] values = new float[img.height * img.width];
  for (int y = 0, s = 0; y < img.height; y ++)
  {
    for (int x = 0; x < img.width; x ++, s ++)
    {
      values[s] = edges[y][x];
    }
  }
  values = sort(values);

  // compose output image
  final PImage output = createImage(img.width, img.height, ALPHA);
  output.loadPixels();

  for (int y = 0, s = 0; y < img.height; y ++)
  {
    for (int x = 0; x < img.width; x ++, s ++)
    {
      int v;
      for (v = 0; v < 256; v ++) {
        if (values[(v+1) * img.width * img.height / 256 - 1] >= edges[y][x]) break; 
      }
      
      output.pixels[s] = v;
    }
  }

  output.updatePixels();
  return output;
}

void setup() {
  img = loadImage("obama.png");
  
  this.surface.setResizable(true);
  this.surface.setSize(img.width + 128, img.height + 128);
  this.surface.setResizable(false);

  edgeImg = edgeDetect(img);
  
  if (grayscale) img.filter(GRAY);

  if (paletteEnable == true) {
    // build a reduced-color palette
    color[] palette = new color[int(pow(paletteDepth + 1, 3))];
    for (int r = 0, s = 0; r <= paletteDepth; r ++)
      for (int g = 0; g <= paletteDepth; g ++)
        for (int b = 0; b <= paletteDepth; b ++, s ++)
        {
          palette[s] = color(r * Math.nextAfter(256, 0) / paletteDepth, g * Math.nextAfter(256, 0) / paletteDepth, b * Math.nextAfter(256, 0) / paletteDepth); 
          //println("Palette - entry " + s + ": " + red(palette[s]) + ", " + green(palette[s]) + ", " + blue(palette[s]));
          println(red(palette[s]) + " " + green(palette[s]) + " " + blue(palette[s]));
        }
    
    // remap every image pixel to closest palette (distance formula)
    img.loadPixels();
    for (int s = 0; s < img.width * img.height; s ++)
    {
      int best = 0;
      float dist = Float.MAX_VALUE;
      color val = img.pixels[s];
      for (int i = 0; i < palette.length; i ++) {
        float newDist = sqrt( pow(red(palette[i]) - red(val), 2) +
                              pow(green(palette[i]) - green(val), 2) +
                              pow(blue(palette[i]) - blue(val), 2));
        if (newDist < dist) { dist = newDist; best = i; }
      }
      img.pixels[s] = palette[best];
    }
    img.updatePixels();
  }

  // background color (black)
  background(0);
  
  rectMode(CENTER);
}

int r = 0;
void draw() {
  
  // collect indices of all pixels at this radius
  IntList indices = new IntList();
  for (int i = 0; i < edgeImg.width * edgeImg.height; i ++)
    if (edgeImg.pixels[i] == r)
      indices.append(i);

  // shuffle the indices
  indices.shuffle();

  int a;
  if (alphaBlend == 0) {
    a = 255;
  } else if (alphaBlend == 1) {
    a = 80;
  } else if (alphaBlend == 2) {
    a = r + 1;
  } else if (alphaBlend == 3) {
    a = 255 - r;
  } else {
    a = 255 - round(255 * pow(r / 255.0, 1.0 / 2.2));
  }
  //println("r=" + r + ": " + indices.size() + ",  a=" + a);

  for (int i : indices) {  
    int x = i % edgeImg.width;
    int y = i / edgeImg.width;
    if (shape == 0) {
      // ellipse
      noStroke();
      fill(img.pixels[i], a);
      
      circle(x + 64, y + 64, (256 - r) / 2);
    } else if (shape == 1) {
      // line
      stroke(img.pixels[i], a);
      
      float theta = angle + random(-variance / 2, variance / 2);
      
      float x1 = 64 + x - cos(theta) * (256 - r) / 4;
      float y1 = 64 + y + sin(theta) * (256 - r) / 4;
      float x2 = 64 + x + cos(theta) * (256 - r) / 4;
      float y2 = 64 + y - sin(theta) * (256 - r) / 4;
      
      strokeCap(PROJECT);
      strokeWeight(log(256 - r));
      line(x1, y1, x2, y2);
    } else if (shape == 2) {
      // box
      noStroke();
      fill(img.pixels[i], a);
      
      square(x + 64, y + 64, (256 - r) / 2);
    }
  }

//  saveFrame();
  r ++;
  if (r > limit) {
    noLoop();
  }
}
