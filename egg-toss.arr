use context essentials2021
import reactors as R
import image as I

############  Data  ############

data PlatformLevel:
  | top
  | middle
  | bottom
end

data GameStatus:
  | ongoing
  | transitioning(ticks-left :: Number)
  | game-over
end

############  Types  ############

type Platform = {
  x :: Number,
  y :: Number,
  dx :: Number,
}

type Egg = {
  x :: Number,
  y :: Number,
  dx :: Number,
  dy :: Number,
  ay :: Number,
  is-airborne :: Boolean,
}

type State = {
  game-status :: GameStatus,
  egg :: Egg,
  top-platform :: Platform,
  middle-platform :: Platform,
  bottom-platform :: Platform,
  current-platform :: PlatformLevel,
  other-platforms :: List<Platform>,
  score :: Number,
  lives :: Number,
  key-press-check :: Number
}

############  Constants  ############

screen-width = 300
screen-height = 500
fps = 60
pan-ticks = 180
pan-speed = 250 / 180
mid-plat-pan-speed = 255 / 180
lives-count = 6

egg-rad = 15
platform-length = 50
platform-width = 10
platform-half-length = platform-length / 2
platform-half-width = platform-width / 2
platform-velocity = [list:(-500 + num-random(401)) / 100, (100 + num-random(401)) / 100]
platform-bot-figure = rectangle(platform-length, platform-width, "solid", "dark-goldenrod") 
platform-figure = overlay-align("center", "top",
  rectangle(platform-length, platform-half-width , "solid", "medium-forest-green"), platform-bot-figure)

egg-jump-height = -13
egg-acc = 0.4

left-wall-x = platform-half-length
right-wall-x = screen-width - platform-half-length


############  Random Gen ############

fun x-generator(gen :: Number) -> Number:
  platform-length + num-random((screen-width - (2 * platform-length)) + 1)
end

fun dx-generator(gen :: Number) -> Number:
  [list:(-500 + num-random(401)) / 100, (100 + num-random(401)) / 100].get(num-random(2))
end

fun plat-generator(gen :: String) -> Platform:
  height = 
    if gen == "Bot":
      screen-height * (3 / 4)
    else if gen == "Mid":
      screen-height * (1 / 2)
    else if gen == "Top":
      screen-height * (1 / 4)
    else if gen == "Off Mid":
      (screen-height * (0)) - platform-half-width
    else:
      screen-height * (0 - (1 / 4))
    end
  { x: x-generator(0),
    y: height,
    dx: dx-generator(0),
  }
end

fun rand-state-generator(gen :: Number) -> State:
  
  rand-bottom = plat-generator("Bot")

  rand-egg = {
    x: rand-bottom.x,
    y: (screen-height * (3 / 4)) - (egg-rad + platform-half-width),
    dx: 0,
    dy: 0,
    ay: 0,
    is-airborne: false,
  }
  
  {
    game-status: ongoing,
    egg: rand-egg,
    top-platform: plat-generator("Top"),
    middle-platform: plat-generator("Mid"),
    bottom-platform: rand-bottom,
    current-platform: bottom,
    other-platforms: [list: plat-generator("Off Mid"), plat-generator("Off Top")],
    score: 0,
    lives: lives-count,
    key-press-check: 0
  }
end


############  Initial State Constants  ############

init-bottom = plat-generator("Bot")

init-egg = {
  x: init-bottom.x,
  y: (screen-height * (3 / 4)) - (egg-rad + platform-half-width),
  dx: 0,
  dy: 0,
  ay: 0,
  is-airborne: false,
}

init-state = {
  game-status: ongoing,
  egg: init-egg,
  top-platform: plat-generator("Top"),
  middle-platform: plat-generator("Mid"),
  bottom-platform: init-bottom,
  current-platform: bottom,
  other-platforms: [list: plat-generator("Off Mid"), plat-generator("Off Top")],
  score: 0,
  lives: lives-count,
  key-press-check: 0
}


############  Functions  ############

############  Drawing  ############

fun draw-egg(state :: State, bg :: Image) -> Image:
  egg = circle(egg-rad, "solid", "navajo-white") 
  I.place-image(egg, state.egg.x, state.egg.y, bg)  
end

fun draw-plat(plat :: Platform, bg :: Image) -> Image:
  I.place-image(platform-figure, plat.x, plat.y, bg) 
end

fun draw-plats(state :: State, bg :: Image) -> Image:
  if state.current-platform == top:
    plat-list = [list: state.bottom-platform, state.middle-platform, state.top-platform, state.other-platforms.get(0), state.other-platforms.get(1)]
    plat-list.foldr(draw-plat(_,_), bg)
  else:
    plat-list = [list: state.bottom-platform, state.middle-platform, state.top-platform]
    plat-list.foldr(draw-plat(_,_), bg)
  end
end

fun draw-score(state :: State, bg :: Image) -> Image:
  score = text("Score: " + num-to-string(state.score), 24, "black")
  I.place-image(score, screen-width / 2, screen-height / 8, bg)  
end

fun draw-lives(state :: State, bg :: Image) -> Image:
  lives = text("Lives: " + num-to-string(state.lives), 18, "black")
  I.place-image(lives, screen-width * (17 / 20), screen-height / 20, bg)  
end

fun draw-game-over(state :: State, bg :: Image) -> Image:
  if state.game-status == game-over:
    gg = text("GAME OVER", 30, "red")
    I.place-image(gg, screen-width / 2, screen-height / 3, bg)  
  else:
    bg
  end
end

fun draw-try-again(state :: State, bg :: Image) -> Image:
  if state.game-status == game-over:
    try-again = text("Press Space to Try Again", 24, "dark-olive-green")
    I.place-image(try-again, screen-width / 2, screen-height * (5 / 9), bg)  
  else:
    bg
  end
end

fun draw-handler(state :: State) -> Image:
  canvas = empty-color-scene(screen-width, screen-height, "light-blue")

  canvas
    ^ draw-egg(state, _ )
    ^ draw-plats(state, _ )
    ^ draw-score(state, _ ) 
    ^ draw-lives(state, _ )  
    ^ draw-game-over(state, _ )   
    ^ draw-try-again(state, _ )   
end

############  Keys  ############

fun key-handler(state :: State, key :: String) -> State:
  if key == " ":
    cases (GameStatus) state.game-status:
      | ongoing => 
        if state.key-press-check == 0:
          state.{
            egg: state.egg.{dy: egg-jump-height, ay: egg-acc, is-airborne: true},
            key-press-check: state.key-press-check + 1}
        else:
          state
        end 
      | transitioning(ticks-left) => state
      | game-over => rand-state-generator(0)
    end
  else:
    state
  end
end 


############  Ticks  ############

fun update-egg-y-velocity(state :: State) -> State:
  state.{egg: state.egg.{dy: state.egg.dy + state.egg.ay}}
end

fun update-egg-y-coord(state :: State) -> State:
  state.{egg: state.egg.{y: state.egg.y + state.egg.dy}}
end

fun update-top-plat-x-coord(state :: State) -> State:
  is-hitting-left-wall = state.top-platform.x < left-wall-x
  is-hitting-right-wall = state.top-platform.x > right-wall-x

  if is-hitting-left-wall:
    state.{top-platform: state.top-platform.{dx: 0 - state.top-platform.dx, x: left-wall-x}}
  else if is-hitting-right-wall:
    state.{top-platform: state.top-platform.{dx: 0 - state.top-platform.dx, x: right-wall-x}}
  else:
    state.{top-platform: state.top-platform.{x: state.top-platform.x - state.top-platform.dx}}
  end
end

fun update-mid-plat-x-coord(state :: State) -> State:
  is-hitting-left-wall = state.middle-platform.x < left-wall-x
  is-hitting-right-wall = state.middle-platform.x > right-wall-x

  if is-hitting-left-wall:
    state.{middle-platform: state.middle-platform.{dx: 0 - state.middle-platform.dx, x: left-wall-x}}
  else if is-hitting-right-wall:
    state.{middle-platform: state.middle-platform.{dx: 0 - state.middle-platform.dx, x: right-wall-x}}
  else:
    state.{middle-platform: state.middle-platform.{x: state.middle-platform.x - state.middle-platform.dx}}
  end
end

fun update-bot-plat-x-coord(state :: State) -> State:
  is-hitting-left-wall = state.bottom-platform.x < left-wall-x
  is-hitting-right-wall = state.bottom-platform.x > right-wall-x

  if is-hitting-left-wall:
    state.{bottom-platform: state.bottom-platform.{dx: 0 - state.bottom-platform.dx, x: left-wall-x}}
  else if is-hitting-right-wall:
    state.{bottom-platform: state.bottom-platform.{dx: 0 - state.bottom-platform.dx, x: right-wall-x}}
  else:
    state.{bottom-platform: state.bottom-platform.{x: state.bottom-platform.x - state.bottom-platform.dx}}
  end
end

fun egg-on-plat(state :: State) -> State:
  fun stick-plat(plat :: Platform) -> State:
    egg-left-wall-check = state.egg.x < egg-rad 
    egg-right-wall-check = state.egg.x > (screen-width - egg-rad)
    plat-left-wall-check = plat.x >= left-wall-x
    plat-right-wall-check = plat.x <= right-wall-x
    if state.key-press-check == 0:
      if egg-left-wall-check and plat-left-wall-check:
        state.{egg: state.egg.{x: egg-rad}}
      else if egg-right-wall-check and plat-right-wall-check:
        state.{egg: state.egg.{x: screen-width - egg-rad}}
      else:
        state.{egg: state.egg.{x: state.egg.x - plat.dx}}
      end
    else:
      state
    end
  end

  cases (PlatformLevel) state.current-platform:
    |top => state.{game-status: transitioning(pan-ticks)}
    |middle => stick-plat(state.middle-platform)
    |bottom => stick-plat(state.bottom-platform)
  end
end

fun egg-fall-collision(state :: State) -> State:
  fun is-hitting-plat(plat :: Platform) -> Boolean:
    egg-dist-x = num-abs(state.egg.x - plat.x)
    egg-dist-y = num-abs(state.egg.y - plat.y)

    if (egg-dist-x > (platform-half-length + egg-rad)) or (egg-dist-y > (platform-half-width + egg-rad)):
      false
    else if (egg-dist-x <= platform-half-length) or (egg-dist-y <= platform-half-width):
      true
    else:
      egg-dist-sqr = num-sqr(egg-dist-x - platform-half-length) + num-sqr(egg-dist-y - platform-half-width)

      egg-dist-sqr <= num-sqr(egg-rad)
    end
  end

  fun plat-collide(plat :: Platform) -> State:
    plat-level = 
      if plat == state.middle-platform:
        middle
      else:
        top
      end
    is-between-the-platform = (state.egg.x < (plat.x + platform-half-length)) and (state.egg.x > (plat.x - platform-half-length)) 

    if (state.egg.is-airborne == true) and (state.egg.dy >= 0) and (is-hitting-plat(plat) == true) and is-between-the-platform:
      state.{current-platform: plat-level, 
        key-press-check: 0,
        score: state.score + 1,
        egg: state.egg.{y: plat.y - (egg-rad + platform-half-width),
            dy: 0,
            ay: 0,
          is-airborne:false} }
    else:
      state
    end
  end

  cases (PlatformLevel) state.current-platform:
    |top => state
    |middle => plat-collide(state.top-platform)
    |bottom => plat-collide(state.middle-platform)
  end
end

fun life-remover(state :: State) -> State:
  fun egg-fall(plat :: Platform) -> State:
    if (state.egg.is-airborne == true) and (state.egg.y > screen-height) and (state.lives > 0):
      state.{lives: state.lives - 1, key-press-check: 0, egg: state.egg.{x: plat.x,
            y: plat.y - (egg-rad + platform-half-width),
            dy: 0,
          ay: 0}}
    else if state.lives == 0:
      state.{game-status: game-over}
    else:
      state
    end
  end
  cases (PlatformLevel) state.current-platform:
    |top => state
    |middle => egg-fall(state.middle-platform)
    |bottom => egg-fall(state.bottom-platform)
  end
end

fun pan-down(state :: State, ticks :: Number) -> State:
  if ticks > 0:
    state.{game-status: transitioning(ticks - 1),
      egg: state.egg.{y: state.egg.y + pan-speed}, 
      top-platform: state.top-platform.{y: state.top-platform.y + pan-speed},
      middle-platform: state.middle-platform.{y: state.middle-platform.y + (mid-plat-pan-speed)},
      bottom-platform: state.bottom-platform.{y: state.bottom-platform.y + pan-speed},
      other-platforms: [list: state.other-platforms.get(0).{y: state.other-platforms.get(0).y + mid-plat-pan-speed}, state.other-platforms.get(1).{y: state.other-platforms.get(1).y + pan-speed}]
    }
  else if ticks == 0:
    state.{bottom-platform: state.top-platform}.
    {middle-platform: state.other-platforms.get(0)}.
    {top-platform: state.other-platforms.get(1)}.
    {other-platforms: [list: plat-generator("Off Mid"), plat-generator("Off Top")]}.
    {current-platform: bottom}.
    {game-status: transitioning(ticks - 1)}
  else:
    state.{game-status: ongoing}
  end
end

fun tick-handler(state :: State) -> State:
  cases (GameStatus) state.game-status:
    | ongoing => 
      state
        ^ update-top-plat-x-coord(_)
        ^ update-mid-plat-x-coord(_)
        ^ update-bot-plat-x-coord(_)
        ^ egg-on-plat(_)
        ^ update-egg-y-velocity(_)
        ^ update-egg-y-coord(_)
        ^ egg-fall-collision(_)
        ^ life-remover(_)
    | transitioning(ticks-left) => 
      state
        ^ pan-down(_, ticks-left)
    | game-over => state
  end
end



############  Main  ############

world = reactor:
  title: "CS 12 MP Project: Simple Egg Toss",
  init: init-state,
  to-draw: draw-handler,
  seconds-per-tick: 1 / fps,
  on-tick: tick-handler,
  on-key: key-handler,
end

R.interact(world)