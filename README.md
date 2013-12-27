Voxel Mars
==========

## Explore every corner of the red planet.<sup><sup><sup>in your browser</sup></sup></sup>

In 1996, the [Mars Orbiter Laser Altimeter (MOLA)](http://en.wikipedia.org/wiki/Mars_Orbiter_Laser_Altimeter) flew aboard [Mars Global Surveyor](http://en.wikipedia.org/wiki/Mars_Global_Surveyor). Using infrared laser pulses, it created a precise map of the planet's topography.

![MOLA](http://i.imgur.com/fqkYKU5.gif)

We're loading this data onto the awesome webgl-based [voxel.js](http://voxeljs.com/) engine so that you can take a hike through Valles Marineris, climb up Olympus Mons and say hello to Curiosity on Gale Crater.

![Voxel Mars](http://i.imgur.com/tKvgHfU.jpg)

This release is a very early alpha; right now you can freely roam through the entire surface (well, except the poles) of a scaled down Mars; we're using the highest resolution map provided by NASA, at 463 meters per pixel. Since your avatar is ~1.5 voxel high, yes, you're seeing Mars through the eyes of a ~694m tall giant.

Future ideas include:
  - interpolate MOLA data as far as possible to get closer to human scale

  - use HiGHRISE DTMs (available in select locations with a resolution of ~2m per pixel)

  - a science-based (no dragons) survival mode on which you have to generate your oxygen and fuel, extract your water, grow your food, make martian bricks, etc

  - use voxel-sky to add the sun, phobos and deimos
  
  - open Google Mars in your location
  
  - add every lander and rover ever sent to Mars and put them at their correct locations
  
  - allow player to fly in "tourism" mode
