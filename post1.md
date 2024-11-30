---
layout: post
title: LÖVE Tutorial - Metaballs
author: Canoi Gomes
date: '2017-01-22T18:39:01-03:00'
category: Tutorial
tumblr_url: https://canoigomes.tumblr.com/post/156235109281/tutorial-metaballs-on-love2d
---
Hi, __everyone__. This is my first tutorial haha. I always wanted to make some tutorial to help people with programming, well, with focus on gamedev. So i was thinking some thing that i can teach, and these days, i learn to make a simple metaballs effect, using blurred image and alpha threshold. And why not teach it to other people, right? haha This tutorial uses love2d as game engine/framework, but i think you can easily adapt to a game engine/framework you are using.

![image](https://66.media.tumblr.com/e90ca6b42125c5d2a70e6a9f08bee055/tumblr_inline_ok7dk3UZRv1uuq5lf_540.gif)<!-- more -->

This is the image i’ll use for the metaball:

![image](https://66.media.tumblr.com/65acbf0216d35d6ee76fca8ea205756e/tumblr_inline_ok7dkgvfjc1uuq5lf_540.png)

Let’s start our code. First, i’ll create a function to create our metaballs, and a table to hold them all

```lua
metaballs = {}
function createMetaball(x, y)
  local metaball = {
    x = x or 0,
    y = y or 0,
    vx = 0,
    vy = 0,
    size = 1
  }
  return metaball
end

function love.load()
end

function love.update(dt)
end

function love.draw()
end
```

The metaball properties:

- `x:` x position of metaball
- `y:` y position of metaball
- `vx:` x velocity of metaball
- `vy:` y velocity of metaball
- `size:` the metaball scale.

Ok, now we have to load our image and create a canvas, how i'll use the same image for all metaballs, i’ll create a global var for it.

- BOOOOOOOOORA
 - **bora?**: *bora*
  - Teste

```lua
metaballs = {}
function createMetaball(x, y)
  local metaball = {
    x = x or 0,
    y = y or 0,
    vx = 0,
    vy = 0,
    size = 1
  }
  return metaball
end

function love.load()
  metaball_image = love.graphics.newImage("metaball.png")
  canvas = love.graphics.newCanvas(canvas_width,canvas_height)
end

function love.update()
end

function love.draw()
end
```

Now, let’s setup the canvas, in this example i’ll draw a metaball on the mouse pos:

```lua 
metaballs = {}
function createMetaball(x, y)
  local metaball = {
    x = x or 0,
    y = y or 0,
    vx = 0,
    vy = 0,
    size = 1
  }
  return metaball
end

function love.load()
  metaball_image = love.graphics.newImage("metaball.png")
  canvas = love.graphics.newCanvas(canvas_width,canvas_height)
end

function love.update()
  mx, my = love.mouse.getPosition()
end

function love.draw()
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0,0,0,0)
  love.graphics.draw(metaball_image, mx, my)
  for i,v in ipairs(metaballs) do
    love.graphics.draw(metaball_image, v.x, v.y, 0, v.size, v.size)
  end
  love.graphics.setCanvas()
end
```

Let’s write our Alpha Threshold shader, and apply in the canvas. Basically an Alpha Threshold shader is a shader that limit our alpha to a certain value.

```glsl
vec4 effect(vec4 color, Image texture, vec2 tex_coord, vec2 screen_coord) { 
  vec4 pixel = Texel(texture, tex_coord); 
  if (pixel.a <= threshold)
    pixel.a = 0.0;
  return pixel * color;
}

```

Where `threshold` is our alpha limit, it has to be a value between 0 and 1

So, if the pixel alpha (`pixel.a`) is minor or equal than the threshold value (`threshold`), `pixel.a = 0`


```lua    
metaballs = {}
function createMetaball(x, y)
  local metaball = {
    x = x or 0,
    y = y or 0,
    vx = 0,
    vy = 0,
    size = 1
  }
  return metaball
end

function love.load() 
  metaball_image = love.graphics.newImage("metaball.png")
  canvas = love.graphics.newCanvas(canvas_width,canvas_height)
  shadersrc = [[ 
    vec4 effect(vec4 color, Image texture, vec2 tex_coord, vec2 screen_coord) { 
      vec4 pixel = Texel(texture, tex_coord); 
      if (pixel.a <= 0.6)
        pixel.a = 0.0;
      return pixel * color;
    } ]]
  shader = love.graphics.newShader(shadersrc)
end

function love.update(dt)
  mx, my = love.mouse.getPosition()
end

function love.draw()
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0,0,0,0)
  love.graphics.draw(metaball_image, mx, my)
  for i,v in ipairs(metaballs) do
    love.graphics.draw(metaball_image, v.x, v.y, 0, v.size, v.size)
  end
  love.graphics.setCanvas()
  love.graphics.setShader(shader)
  love.graphics.draw(canvas)
  love.graphics.setShader()
end
```

I set the threshold value directly on shader, but you can create a uniform for it. 

Well, now should be all working, all you have to do is add metaballs to the `metaballs` table. I’ll make an example to create metaballs on mouse click with random properties, and make metaballs kick on touch screen bounds.

```lua    
metaballs = {}
function createMetaball(x, y)
  local metaball = {
    x = x or 0,
    y = y or 0,
    vx = 0,
    vy = 0,
    size = 1,
    update = function(self, dt)
      self.x = self.x + (self.vx * dt) 
      self.y = self.y + (self.vy * dt) 
      if self.x >= screen_width or self.x <= 0 then 
        self.vx = self.vx * -1 
      end 
      if self.y >= screen_height or self.y <=0 then
        self.vy = self.vy * -1
      end
    end
  }
  return metaball
end

function love.load()
  metaball_image = love.graphics.newImage("metaball.png")
  canvas = love.graphics.newCanvas(canvas_width,canvas_height)
  shadersrc = [[ 
    vec4 effect(vec4 color, Image texture, vec2 tex_coord, vec2 screen_coord) {
      vec4 pixel = Texel(texture, tex_coord);
      if (pixel.a <= 0.6)
        pixel.a = 0.0;
      return pixel * color;
      } ]]
  shader = love.graphics.newShader(shadersrc)
end

function love.update(dt)
  mx, my = love.mouse.getPosition()
  if love.mouse.isDown(1) then
    local meta = createMetaball(mx, my)
    meta.vx = love.math.random(-200, 200)
    meta.vy = love.math.random(-200, 200)
    meta.size = love.math.random(0.2, 0.4)
    table.insert(metaballs, meta)
  end
  for i,v in ipairs(metaballs) do
    v:update(dt)
  end
end

function love.draw()
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0,0,0,0)
  love.graphics.draw(metaball_image, mx, my, 0, 1, 1, img_width/2, img_height/2)
  for i,v in ipairs(metaballs) do
    love.graphics.draw(metaball_image, v.x, v.y, 0, v.size, v.size)
  end
  love.graphics.setCanvas()
  love.graphics.setShader(shader)
  love.graphics.draw(canvas)
  love.graphics.setShader()
end
```     

Okay, all done :D. Hope it would be helpful.

