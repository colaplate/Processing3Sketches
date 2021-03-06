FragmentTree tree;
int slices;
float rotationChance;
float translationChance;
float shearChance;
float explode;
float explodePerLevel;
float phase;
boolean freeze;
int counter;
int numFrames;
float zoom;
float tx, ty, ax, ay, az;
float ttx, tty, ttz;
float sscale;
boolean gui;
PShader filter, genFilter, post;
color bkg;
PImage[] textures;
PGraphics generator;

void setup() {
  fullScreen(P3D);
  smooth();
  noCursor();
  post=loadShader("vignette.glsl");
  explode=0;
  numFrames=1800;
  textures=new PImage[40];
  generator=createGraphics(800, 800,P3D);
  generator.smooth();
  generator.beginDraw();
  generator.background(255);
  generator.endDraw();
  init();
  bkg=color(255, 140, 11);
  textureMode(NORMAL);
}

void init() {
  filter=(random(100)<50)?(random(100)<50.0)?loadShader("mirrorx.glsl"):loadShader("mirrory.glsl"):(random(100)<50.0)?loadShader("mirrorxy.glsl"):loadShader("donothing.glsl");
 
  int seed=(int)random(10000000);
  println(String.format("%08d", seed));
  randomSeed(seed);
  initialGeometry();
  translationChance=0.32;
  rotationChance=0.32;
  shearChance=0.1;
  //stretchChance=1.0-translationChance-rotationChance-shearChance;
  slices=25;
  tree=new FragmentTree(initialGeometry());
  for (int r=0; r<slices; r++) {
    slice(r, color(255), color(0));
  }
  counter=0;
  zoom=1.0;
  tx=ty=ax=ay=az=0.0;
  freeze=false;
  gui=true;
  for (int i=0; i<40; i++) {
    generator.beginDraw();
    generator.background(255);
    generator.pushMatrix();
    generator.translate(generator.width/2, generator.height/2);
    generator.noStroke();
    generator.fill(0);
    float d=random(20, 100);
    float t=random(20, 100);
    float a=random(PI);
    generator.rotate(a);
    for (int j=-50; j<=50; j++) {
      generator.rect(j*(d+t)-0.5*d, -10000, d, 20000);
    }
     genFilter=(random(100)<50)?(random(100)<50.0)?loadShader("mirrorx.glsl"):loadShader("mirrory.glsl"):(random(100)<50.0)?loadShader("mirrorxy.glsl"):loadShader("donothing.glsl");
    generator.filter(genFilter);
    generator.popMatrix();
    generator.endDraw();
    textures[i]=generator.get();
  }
}

ArrayList<SliceMesh> initialGeometry() {
  ArrayList<SliceMesh> sliceMeshes=new ArrayList<SliceMesh>();
  SliceMesh sliceMesh;
  sliceMesh=new SliceMesh();
  sliceMesh.create(MeshDataFactory.createBoxWithCenterAndSize(0, 0, 0, 420, 420, 420, color(0)));
  sliceMeshes.add(sliceMesh);
  tree=new FragmentTree(sliceMeshes);
  return sliceMeshes;
}

void slice(int slicecount, color col, color col2) {
  Transformation M;
  int trial=0;
  do {

    float sliceRoll=random(1.0);
    if (sliceRoll<translationChance) {
      M=sliceAndTranslate();
    } else if (sliceRoll<rotationChance+translationChance) {
      M=sliceAndRotate();
    } else  if (sliceRoll<rotationChance+translationChance+shearChance) {
      M=sliceAndShear();
    } else {
      M=sliceAndStretch();
    }
    trial++;
  } while (tree.minDistance(M.plane)<5 && trial<20);

  M.level=slicecount;
  tree.split(M, col, col2);
}

void draw() {
  float phase=0.5-0.52*cos(radians(360.0/numFrames*counter));
  background(bkg);
  filter(post);
  translate(width/2+tx, height/2+ty);
  pointLight(255, 255, 255, 1000, 0, 0);
  pointLight(255, 255, 255, 0, -1000, 0);
  pointLight(255, 255, 255, 0, 0, 1000);
  rotateZ(radians(180+az));
  rotateX(radians(ax));
  rotateY(radians(ay+map(counter, 0, numFrames/2, 0, 360)));

  scale(zoom);
  tree.setPhase((slices+1)*phase);
  float[] extents=tree.getExtents();
  ttx=0.95*ttx-0.025*(extents[0]+extents[3]);
  tty=0.95*tty-0.025*(extents[1]+extents[4]);
  ttz=0.95*ttz-0.025*(extents[2]+extents[5]);
  sscale=min(1.0, min(1000.0/(extents[3]-extents[0]), 1000.0/(extents[4]-extents[1]), 1000/(extents[5]-extents[2])));
  scale(sscale);
  translate(ttx, tty, ttz);
  strokeWeight(1.0/(zoom*sscale));
  stroke(0, 55);
  fill(0, 45+170*sq(2.0*map(counter, 0, numFrames, 0, 1)-1.0));
  tree.draw(textures);
  filter(filter);
  if (!freeze) counter++;
  if (counter==numFrames) {
    init();
  }
}


void keyPressed() {
  if (key==' ') {
    freeze=!freeze;
    ax=0;
    ay=0;
    az=0;
  } else if (key=='n') {
    init();
  } else if (key=='f') {
    if (freeze) {
      counter=max(counter-5, 0);
    }
  } else if (key=='F') {

    if (freeze) {
      counter=min(counter+5, 1800);
    }
  } else if (key=='x') {
    if (freeze) {
      ax-=5;
      if (ax<=-180) ax+=360;
    }
  } else if (key=='X') {
    if (freeze) {
      ax+=5;
      if (ax>180) ax-=360;
    }
  } else if (key=='y') {
    if (freeze) {
      ay-=5;
      if (ay<=-180) ay+=360;
    }
  } else if (key=='Y') {
    if (freeze) {
      ay+=5;
      if (ay>180) ay-=360;
    }
  } else if (key=='z') {
    if (freeze) {
      az-=5;
      if (az<=-180) az+=360;
    }
  } else if (key=='Z') {
    if (freeze) {
      az+=5;
      if (az>180) az-=360;
    }
  } else if (key=='+') {
    zoom+=0.05;
  } else if (key=='-') {
    zoom-=0.05;
  } else if (key== CODED) {
    if (keyCode==UP) {
      ty-=10;
    } else if (keyCode==DOWN) {
      ty+=10;
    } else if (keyCode==RIGHT) {
      tx+=10;
    } else if (keyCode==LEFT) {
      tx-=10;
    }
  }
}
