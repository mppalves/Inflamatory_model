breed [histaminas histamina]
breed [macrofagos macrofago]
breed [linfocitos-T linfocito-T]
breed [bacterias bacteria]
breed [citosinas citosina]
breed [mastocitos mastocito]

histaminas-own [ step hspeed age ]
bacterias-own  [ benergy speed food-efficiency resistance step-cost ]
macrofagos-own [ menergy mspeed kill? ]
citosinas-own  [ cenergy ]
patches-own    [
                 derme?         ;; if the patch is derme or blood vesel
                 food-energy    ;; energy available for bacterias
                 cito-chemical  ;; citocina trace chemical
                 slow-speed?    ;;
                 dead?
                 cito-burst?
                 max-food
                 recovered?
               ]

globals
[
  edge-patches                   ; border patches where food-energy should remain 0
  main-patches                   ; patches not on the border
  blood-vesel                    ; selecting patches that will be part of me blood vesel
  derme                          ; intersticial tissue
  bacteria-color                 ; Color of bacteria.
  bacteria-size                  ; Size of bacteria, also virus scale factor.
  max-food-energy                ; Max amount of food energy per patch.
  min-reproduce-energy           ; Min energy required for bacteria to reproduce.
  food-cells-eat                 ; Amount of food bacteria eat each time step.
  macrofago-color                ; determine the color of macrofago cells
  macrofago-size                 ; determine the size of macrofago cells
  eaosinofilo-color              ; determine the color of macrofago cells
  eaosinofilo-size               ; determine the size of macrofago cells
  histaminas-color
  histaminas-size
]



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETUP PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup

  clear-all

  ;; starting up variables
  ask patches [set derme? true]
  set blood-vesel patch-set patches with [pxcor > (random 2 + max-pxcor / 2 ) and pxcor < (random 2 + max-pxcor / 1.1)]
  ask blood-vesel [set derme? false]
  set edge-patches patches with [count neighbors != 8]
  set main-patches patches with [count neighbors = 8]
  ask main-patches [ set food-energy random-float 100 ]
  ask edge-patches [ set food-energy 0 ]

  set bacteria-color  orange
  set-default-shape bacterias "bacteria"
  set bacteria-size 1

  set macrofago-color  yellow
  set-default-shape macrofagos "macrofago"
  set macrofago-size 2

  set-default-shape mastocitos "mastocito"
  set eaosinofilo-color red
  set eaosinofilo-size 3

  set-default-shape histaminas "dot"
  set histaminas-color red
  set histaminas-size 1

  set min-reproduce-energy 50
  set max-food-energy 100
  set food-cells-eat 25

  ask patches [ set cito-burst? false ]

  ;; coloring scenario
  repeat 3 [diffuse food-energy 1]
  color-connective-tissue
  color-blood-vessel
  ask patches [ set max-food food-energy ] ; locking the maximum energy value per cell
  reset-ticks
  ;; starting up the cells
  create-macrofagos 50 [
    setxy random-xcor random-ycor
    set size macrofago-size
    set color macrofago-color
    set menergy 100
    ;set mspeed 0.4
    set mspeed macrofago-speed ; macrofago-speed = 0.4

  ]

  create-bacterias 4 [
    setxy random-xcor random-ycor
    set size bacteria-size
    set color bacteria-color
    set benergy random-normal (min-reproduce-energy / 2) (min-reproduce-energy / 10)
    ;set speed 0.15
    set speed bacterias-speed ; bacterias-speed = 0.15
    set food-efficiency 1
    set step-cost 0.1

  ]

  create-mastocitos initial-mastocitos [
    setxy random-xcor random-ycor
    set size eaosinofilo-size
    set color eaosinofilo-color
  ]
  kill-mastocitos

end

;------------------------------ COLOR FUNCTIONS ------------------------------------

to color-connective-tissue
  ask patches
    [ set pcolor scale-color 30 food-energy 0 100 ]
end

to color-blood-vessel
  ask blood-vesel [ set pcolor scale-color red food-energy 0 100 ]
  ask blood-vesel with [ pxcor > max-pxcor / 2 and pxcor < (random 2 + ( 3 + max-pxcor / 2)) ] [ set pcolor 12 ]
  ask blood-vesel with [ pxcor > (random 2 +   (max-pxcor / 1.1 - 2)) and pxcor < (max-pxcor / 1.1 + 1) ] [ set pcolor 12 ]
end

to color-citoquina-patch
  ask patches
    [ if cito-chemical > 0.1 [set pcolor scale-color green cito-chemical  0 1 ]]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; RUN ;;;;;;;;;;;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  macrofagos-live
  citosinas-live
  bacterias-live
  diffuse cito-chemical (10 / 100)
  color-connective-tissue
  color-blood-vessel
  color-citoquina-patch
  ask macrofagos [ in-the-flow ]
  ask bacterias [ in-the-flow ]
  ask patches [ ifelse cito-chemical > 1e-6 [ set cito-chemical cito-chemical * (100 - 7) / 100 ] [set cito-chemical 0]]
  mastocito-live
  histamina-move
  live-endotelium
  tick
end

;----------------------------- MACROFAGOS PROCEDURES ---------------------------

to macrofagos-live
  ask macrofagos [
    move-macrofagos
    fagocitar-bacteria
    in-the-flow
    macrofago-commns
    macrofago-mitosis
    macrofagos-eat-food
    if (menergy <= 0 ) [ die ]
  ]
end

to move-macrofagos
 set menergy (menergy - 1)  ; Bacteria lose energy as they move
  rt random-float 90
  lt random-float 90
  fd 0.25  * mspeed; The lower the speed, the less severe the population oscillations are.
  follow-chemical
end

to fagocitar-bacteria
  ask bacterias-here [
    ask macrofagos-here [ set kill? True ]
    die
  ]
end

to macrofago-commns
  ask macrofagos-here [
    if kill? = true [
      if random 100 > 90 [
      hatch-citosinas 1 [ set cenergy random-normal 20 5
                        set size 0 ]
      set menergy (menergy - 30)
      ]
    ]
    if menergy < 100 [set kill? false]
  ]
end

;to stop-macrofago
;  set speed 0
;end

to in-the-flow
  ;if not derme? [set heading -180 + random-normal 10 5 - 10]
  if not derme? [set heading -180 + random 10 ]
end

to follow-chemical  ;; turtle procedure
  let scent-ahead chemical-scent-at-angle   0
  let scent-right chemical-scent-at-angle  45
  let scent-left  chemical-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead)
  [ ifelse scent-right > scent-left
    [ rt 45 ]
    [ lt 45 ] ]
end

to-report chemical-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report [cito-chemical] of p
end

to macrofago-mitosis ; Bacteria procedure
 let mitosis-sign cito-chemical
 if (mitosis-sign > 100) [
    if random-float 100 > 99 [

    set cito-chemical 0
    hatch 1 [
      rt random 360
      fd 0.25
      set color pink
      set mspeed 0.4
    ]
  ]
]
end


to macrofagos-eat-food ; Bacteria procedure
  ; If there is enough food on this patch, the bacteria eat it and gain energy.
  if food-energy > food-cells-eat [
    if menergy < 500
      [ set menergy menergy + food-cells-eat  / 10 ] ; bacteria gain energy by eating
  ]
end
;----------------------------- BACTERIA PROCEDURES -----------------------------

to bacterias-live
  ask bacterias [
    move-bacterias
    bacterias-eat-food
    reproduce-bacteria
    if (benergy <= 0 ) [ die ]
  ]
end

to move-bacterias ; Bacterias procedure
  set benergy (benergy - step-cost)  ; Bacteria lose energy as they move
  rt random-float 90
  lt random-float 90
  if slow-speed? = true [ set speed 0]
  fd 0.25 * speed

end

to bacterias-eat-food ; Bacteria procedure
  ; If there is enough food on this patch, the bacteria eat it and gain energy.
  if food-energy > food-cells-eat [
    ; Bacteria gain 1/5 the energy of the food they eat (trophic level assumption)
    set food-energy (food-energy - food-cells-eat)
    set benergy benergy + food-cells-eat * food-efficiency ; bacteria gain energy by eating
  ]
end

to reproduce-bacteria ; Bacteria procedure
 let dice random 4
 if (benergy >  min-reproduce-energy) [
    set benergy (benergy / 2)  ; Parent keeps half the cell's energy
    ; Variable inheritance gives the daughter half the cell's energy too
    hatch 1 [
      rt random 360
      fd 0.25

      ;if dice = 1 [ ; speed bonus
      ;ifelse dice-increment > 0 [
      ;  set speed speed + dice-increment * 0.0001
      ;  set step-cost step-cost + dice-increment * 0.001
      ;]
      ;[
      ;  set speed speed + dice-increment * 0.0001
      ;    ifelse step-cost + dice-increment * 0.001  <= 0.1 [ set step-cost 0.1] [set step-cost ( step-cost + dice-increment * 0.001 )]
      ;]
      ;]
      ;if dice = 2 [ ; efficiency bonus
      ;ifelse dice-increment > 0 [
      ;  set food-efficiency (food-efficiency + dice-increment * 0.001)
      ;    ifelse speed - dice-increment * 0.0001 <= 0.05 [set speed 0.5] [set speed speed - dice-increment * 0.0001]
      ;]
      ;[
      ;  set food-efficiency (food-efficiency + dice-increment * 0.001)
      ;  set speed speed - dice-increment * 0.0001
      ;]
      ;]

      ;if dice = 2 [ if random-float 100 > 99 [ set killer? true]]
      ;if dice = 3 [ if random-float 100 > 99 [ set hist-resistent? true]]
      ;if killer? = true [ set color green ]
      ;if hist-resistent? = true [ set color red ]
      ;if faster != 1 [ set color blue ]
      ;if faster != 1 and killer? = true [ set color yellow ]
      ;if faster != 1 and hist-resistent? = true [ set color 113 ]
      ;if faster != 1 and hist-resistent? = true and killer? = true [ set color pink ]

   ]
  ]
end

to-report dice-increment
  report random-normal 100 50 - 100
end

;----------------------------- CITOSINAS PROCEDURES ---------------------------
to citosinas-live
  ask citosinas [
    move-citosinas
    if (cenergy <= 0 ) [ die ]
  ]
end

to move-citosinas ; Bacterias procedure
  set cenergy (cenergy - 0.5)  ; Bacteria lose energy as they move
  fd 0.25 ; The lower the speed, the less severe the population oscillations are.

  let trail-energy cenergy
  ask patch-here [
    set cito-chemical cito-chemical + trail-energy
  ]
 if not can-move? 1 [die] ;; drop some chemical
end

;----------------------------- MASTOCITOS PROCEDURES -----------------------------

to mastocito-live
  ask mastocitos [
   follow-chemical
   anaphylactic
   ]
end

to anaphylactic
 let mitosis-sign cito-chemical
 if (mitosis-sign > anaphylatic-thld) [ ; anaphylatic-thld 20
    hatch-histaminas random-normal 2 1 [
      set size 1
      fd 0.25
      set step random-float 100
      set hspeed 0.4
      set color histaminas-color
      set size histaminas-size
      set age 0
  ]
]
end


;----------------------------- HISTAMINAS PROCEDURES ------------------------------


to histamina-move
  ask histaminas [
    set age age + 1
    set step (step - 1)
     rt random-float 10
     lt random-float 10
    fd 0.25 * hspeed
    if step < 1 [ set hspeed 0
      set slow-speed? true ]
    if age > histamin-effect-duration * 1000 [ ; histamin-effect 100
      set slow-speed? false
      die]
  ]
end

;---------------------------- PATCHES PROCEDURES -----------------------------------

to live-endotelium
 ask blood-vesel [ blood-sprout ]
 ask patches [ signal-derme-death ]
 replenish-derme
 kill-mastocitos
end

to blood-sprout
  if random-float 100 > 99.99 and cito-chemical > 0 [
  sprout-macrofagos 1 [ set color blue
   set mspeed  0.4
   set size 2 ]
  ]
end

to signal-derme-death
  if food-energy < max-food / 5 [
    set dead? true
  ]

  if food-energy > max-food / 3 [
    set cito-burst? false
    set dead? false
  ]

  if dead? = true and cito-burst? = false [
    set cito-chemical 10
    set cito-burst? true ]
end

to replenish-derme
  ask main-patches [
    if food-energy < max-food [ set food-energy food-energy + 0.01
     ]
  ]
end

to kill-mastocitos
  ask blood-vesel [
    ask mastocitos-here [ die ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
214
13
954
754
-1
-1
12.0
1
10
1
1
1
0
0
1
1
-30
30
-30
30
1
1
1
ticks
30.0

BUTTON
8
12
72
45
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
78
12
141
45
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
145
13
208
46
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
961
13
1892
357
Count cells
time
# of cells
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Bacterias" 1.0 0 -3844592 true "" "plot count bacterias"
"Macrofagos blood" 1.0 0 -14070903 true "" "plot count macrofagos with [color = blue]"
"Macrofagos Tissue" 1.0 0 -4699768 true "" "plot count macrofagos with [color = pink]"

PLOT
961
360
1891
510
Anaphylactic attacks
Time
# of histamin particles
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Histamins released" 1.0 0 -8053223 true "" "plot count histaminas"

PLOT
961
512
1889
662
Health status
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Total tissue health" 1.0 0 -16777216 true "" "plot mean [food-energy] of patches"

SLIDER
9
74
209
107
bacterias-speed
bacterias-speed
0
1
0.15
0.01
1
NIL
HORIZONTAL

SLIDER
9
113
209
146
macrofago-speed
macrofago-speed
0
1
0.33
0.01
1
NIL
HORIZONTAL

SLIDER
10
237
210
270
histamin-effect-duration
histamin-effect-duration
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
9
173
210
206
initial-mastocitos
initial-mastocitos
0
100
73.0
1
1
NIL
HORIZONTAL

TEXTBOX
12
57
162
75
Speeds
11
0.0
1

TEXTBOX
11
155
161
173
Initial numbers
11
0.0
1

TEXTBOX
11
217
161
235
Immune response
11
0.0
1

SLIDER
9
279
209
312
anaphylatic-thld
anaphylatic-thld
0
100
15.0
1
1
NIL
HORIZONTAL

MONITOR
5
325
220
370
NIL
mean [speed] of bacterias
17
1
11

PLOT
4
373
209
493
Speed mutation
NIL
NIL
0.0
200.0
0.0
0.3
true
false
"" ""
PENS
"Speed" 1.0 0 -955883 true "" "plot mean [ speed ] of bacterias"

PLOT
4
500
204
620
Food efficiency
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ food-efficiency ] of bacterias"

PLOT
5
623
205
743
plot 2
NIL
NIL
0.0
10.0
0.0
0.5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ step-cost ] of bacterias"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bacteria
true
0
Polygon -7500403 true true 105 90 105 225 120 240 180 240 195 225 195 90 180 75 120 75 105 90
Polygon -7500403 false true 120 60 180 60 210 90 210 240 180 255 120 255 90 240 90 90 120 60

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

linfocitot
true
0
Circle -7500403 true true 146 131 67
Circle -7500403 false true 60 60 180
Circle -7500403 false true 59 44 212

macrofago
true
0
Polygon -7500403 true true 60 60 30 105 45 165 30 195 75 240 120 255 180 240 210 210 240 180 240 150 240 120 225 75 195 75 180 45 120 45 90 45 60 60
Circle -16777216 true false 73 88 92
Line -7500403 true 225 180 255 180
Line -7500403 true 45 195 15 195
Line -7500403 true 165 225 195 255
Line -7500403 true 165 60 180 30
Line -7500403 true 75 75 45 60

mastocito
true
0
Polygon -7500403 true true 150 150
Circle -7500403 true true 23 23 255
Circle -16777216 true false 165 45 30
Circle -16777216 true false 105 45 30
Circle -16777216 true false 60 75 30
Circle -16777216 true false 210 75 30
Circle -16777216 true false 180 105 30
Circle -16777216 true false 135 75 30
Circle -16777216 true false 105 105 30
Circle -16777216 true false 96 156 108
Circle -16777216 true false 45 120 30
Circle -16777216 true false 225 120 30

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
