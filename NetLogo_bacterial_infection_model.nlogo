breed [histamines histamina]
breed [macrophages macrophage]
breed [linfocitos-T linfocito-T]
breed [bacterias bacteria]
breed [cytosines cytosine]
breed [mastocytes mastocyte]

histamines-own [ step    ; distance where histamines are thrown
                 hspeed  ; speed histamines are thrown
                 age ]   ; age of histamine particle

bacterias-own  [ benergy           ; energy of bacteria
                 speed             ; current bacteria movement speed
                 gspeed            ; bacterial genetic speed
                 food-efficiency ]  ; the efficiency in which bateria transforms tissue in food

macrophages-own [ menergy  ; macrophage energy
                  mspeed   ; macrophage speed
                  kill? ]  ; Bolean value true for macrophages that just killed bacteria and false otherwise

cytosines-own  [ cenergy ] ; cytosines kinetic energy

patches-own    [ derme?         ; Boolean determining if the patch is derme or blood vesel
                 food-energy    ; energy available for bacterias and macrophages
                 cito-chemical  ; citocina trace chemical
                 slow-speed?    ; Boolean signaling if the cell is under the effects of histamines
                 dead?          ; Boolean true for cells with less than 1/5 of max-food left and false otherwise
                 cito-burst?    ; Booleand true for cells that just died and relaase a burst of cytosines
                 max-food ]      ; Maximum food available in the cell. This amount is randomized at the beging of the simulation



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
  macrophage-color                ; determine the color of macrophage cells
  macrophage-size                 ; determine the size of macrophage cells
  eaosinofilo-color              ; determine the color of macrophage cells
  eaosinofilo-size               ; determine the size of macrophage cells
  histamines-color
  histamines-size
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

  set bacteria-color  37
  set-default-shape bacterias "bacteria"
  set bacteria-size 1

  set macrophage-color  134
  set-default-shape macrophages "macrophage"
  set macrophage-size 2

  set-default-shape mastocytes "mastocyte"
  set eaosinofilo-color red
  set eaosinofilo-size 3

  set-default-shape histamines "dot"
  set histamines-color red
  set histamines-size 1

  set min-reproduce-energy 50
  set max-food-energy 100
  set food-cells-eat 25

  ask patches [ set cito-burst? false
                set slow-speed? false]

  ;; coloring scenario
  repeat 3 [diffuse food-energy 1]
  color-connective-tissue
  color-blood-vessel
  ask patches [ set max-food food-energy ] ; locking the maximum energy value per cell
  reset-ticks

  ;; starting up the cells
  create-macrophages Initial-num-macrophages [
    setxy random-xcor random-ycor
    set size macrophage-size
    set color macrophage-color
    set menergy 100
    set mspeed macrophage-speed

  ]

  create-bacterias number-init-bacteria [
    setxy random-xcor random-ycor
    set size bacteria-size
    set color bacteria-color
    set benergy random-normal (min-reproduce-energy / 2) (min-reproduce-energy / 10)
    ;set speed 0.15
    set speed bacterias-speed
    set gspeed bacterias-speed
    set food-efficiency 1


  ]

  create-mastocytes initial-mastocytes [
    setxy random-xcor random-ycor
    set size eaosinofilo-size
    set color eaosinofilo-color
  ]
  kill-mastocytes

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
    [ if cito-chemical > 0.1 [set pcolor scale-color 133 cito-chemical  0 1 ]]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; RUN ;;;;;;;;;;;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  macrophages-live
  cytosines-live
  bacterias-live
  diffuse cito-chemical (20 / 100)
  color-connective-tissue
  color-blood-vessel
  color-citoquina-patch
 ; ask macrophages [ in-the-flow-macrophage ]
  ask bacterias [ in-the-flow-bacteria ]
  ask patches [ ifelse cito-chemical > 1e-6 [ set cito-chemical cito-chemical * (100 - 7) / 100 ] [set cito-chemical 0]]
  mastocyte-live
  histamina-move
  live-endotelium
  tick
end

;----------------------------- MACROPHAGES PROCEDURES ---------------------------

to macrophages-live
  ask macrophages [
    move-macrophages
    fagocitar-bacteria
    in-the-flow-macrophage
    macrophage-commns
    macrophage-mitosis
    macrophages-eat-food
    if (menergy <= 0 ) [ die ]
  ]
end

to move-macrophages
 set menergy (menergy - 0.7)  ; macrophages lose energy as they move
  rt random-float 90
  lt random-float 90
  fd 0.25  * mspeed
  follow-chemical
  go-until-empty-here
end

to fagocitar-bacteria
  ask bacterias-here [
    ask macrophages-here [ set kill? True ]
    die
  ]
end

to macrophage-commns
  ask macrophages-here [
    if kill? = true [
      if random 100 > 90 [
      hatch-cytosines 1 [ set cenergy random-normal 25 5
                        set size 0 ]
      set menergy (menergy - 30)
      ]
    ]
    if menergy < 300 [set kill? false]
  ]
end

to go-until-empty-here
    while [any? other macrophages-here]
      [ rt random 360
      fd 0.19 ]

end

to in-the-flow-macrophage
  ifelse chemical-scent-at-angle 0 > 0 [ follow-chemical ]  [
    if not derme? [ set heading -180 + random-normal 20 5 - 20 ] ]
end

to in-the-flow-bacteria
  if not derme?  [set heading -180 + random-normal 20 5 - 20]
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

to macrophage-mitosis ; Bacteria procedure
 let mitosis-sign cito-chemical
 if (mitosis-sign > 50) [
    if random-float 100 > 99 [

    set cito-chemical 0
    hatch 1 [
      rt random 360
      fd 0.25
      set color 134
      set mspeed 0.4
    ]
  ]
]
end


to macrophages-eat-food
  ; If there is enough food on this patch, the macrophage eat it and gain energy.
  if food-energy > food-cells-eat [
    if menergy < 500
      [ set menergy menergy + food-cells-eat  / 10 ] ; macrophage gain energy by eating
        set food-energy (food-energy - food-cells-eat / 500) ; food-energy is decreased by macrophages in smaller rates than bacteria
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
    if slow-speed? = false [
      set food-energy (food-energy - food-cells-eat)
      set benergy benergy + food-cells-eat * food-efficiency ] ; bacteria gain energy by eating and destroying the cells
  ]
end

to reproduce-bacteria ; Bacteria procedure
 let increment dice-increment
 if (benergy >  min-reproduce-energy) [
    set benergy (benergy / 2)  ; Parent keeps half the cell's energy
    ; Variable inheritance gives the daughter half the cell's energy too
    hatch 1 [
      rt random 360
      fd 0.25
      set speed gspeed
      if mutation? = true [
       if random 100 > 90 [ ; speed bonus
        set gspeed gspeed + increment * 0.001
        ]
      ]
      if gspeed >= 0.1 and gspeed < 0.2 [set color 37 ]
      if gspeed >= 0.2 and gspeed < 0.35 [set color 74 ]
      if gspeed >= 0.35 [set color 96 ]
      ; set color speed * 100
   ]
  ]
end
 to-report step-cost
  let x gspeed * 0.6
  report x
 end


to-report dice-increment
  report random-normal 100 20 - 100
end

;----------------------------- CYTOKINES PROCEDURES ---------------------------
to cytosines-live
  ask cytosines [
    move-cytosines
    if (cenergy <= 0 ) [ die ]
  ]
end

to move-cytosines
  set cenergy (cenergy - 0.5)  ; cytokines lose energy as they move
  fd 0.25 ;

  let trail-energy cenergy
  ask patch-here [
    set cito-chemical cito-chemical + trail-energy
  ]
 if not can-move? 1 [die] ; drop some chemical as it passes over the patches
end

;----------------------------- MASTOCYTES PROCEDURES -----------------------------

to mastocyte-live
  ask mastocytes [
   follow-chemical
   anaphylactic
   ]
end

to anaphylactic
 let mitosis-sign cito-chemical
 if (mitosis-sign > anaphylatic-thld) [
    hatch-histamines random-normal 2 1 [
      set size 1
      fd 0.25
      set step random-float 100
      set hspeed 0.4
      set color histamines-color
      set size histamines-size
      set age 0
  ]
]
end


;----------------------------- HISTAMINES PROCEDURES ------------------------------


to histamina-move
  ask histamines [
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
 kill-mastocytes
end

to blood-sprout
  if random-float 100 > 99.995 and cito-chemical > 0 [
  sprout-macrophages 1 [ set color 13
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

to kill-mastocytes
  ask blood-vesel [
    ask mastocytes-here [ die ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
217
13
957
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
1000.0

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
Tissue population of bacteria and immune cells
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
"Bacterias 1st strain" 1.0 0 -3889007 true "" "plot count bacterias with [color = 37]"
"Blood Macrophages" 1.0 0 -8053223 true "" "plot count macrophages with [color = 13]"
"Mitotic Macrophages" 1.0 0 -4757638 true "" "plot count macrophages with [color = 134]"
"Bacteria 2st strain" 1.0 0 -15302303 true "" "plot count bacterias with [color = 74]"
"Bacteria 3rd strain" 1.0 0 -11033397 true "" "plot count bacterias with [color = 96]"

PLOT
961
360
1891
510
Anaphylactic bursts
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
"Histamins released" 1.0 0 -8053223 true "" "plot count histamines"

PLOT
961
512
1889
662
Tissue health
NIL
NIL
0.0
10.0
30.0
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
0.3
0.18
0.01
1
NIL
HORIZONTAL

SLIDER
9
113
209
146
macrophage-speed
macrophage-speed
0
1
0.19
0.01
1
NIL
HORIZONTAL

SLIDER
8
321
208
354
histamin-effect-duration
histamin-effect-duration
0
1
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
9
173
210
206
initial-mastocytes
initial-mastocytes
0
100
50.0
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
9
301
159
319
Immune response
11
0.0
1

SLIDER
7
363
207
396
anaphylatic-thld
anaphylatic-thld
0
40
11.0
1
1
NIL
HORIZONTAL

MONITOR
8
409
208
454
Bacteria avg speed
mean [gspeed] of bacterias
17
1
11

PLOT
6
462
206
582
Bacterial avg speed
NIL
NIL
0.0
200.0
0.0
0.2
true
false
"" ""
PENS
"Speed" 1.0 0 -955883 true "" "plot mean [ gspeed ] of bacterias"

PLOT
6
585
206
705
Bacterial avg feed efficiency
NIL
NIL
0.0
10.0
0.0
0.3
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot 1 / mean [ step-cost ] of bacterias "

SWITCH
6
713
116
746
Mutation?
Mutation?
0
1
-1000

SLIDER
9
213
209
246
Number-init-bacteria
Number-init-bacteria
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
8
252
209
285
Initial-num-macrophages
Initial-num-macrophages
0
100
100.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model illustrates the dynamics of macrophages, bacteria, and mastocytes in inflammatory processes on vascularized epithelium tissue. It can be thought of as a cross-section of skin where invading bacteria feed of the healthy tissue causing damage while triggering the tissue’s immune response.

The immune response is controlled by cytokines, a category of signaling molecules that mediate and regulate immunity, inflammation, and hematopoiesis. Cytokines are released when bacteria feed on the tissue or when a macrophage phagocytes a bacterium. The high concentration of cytokines creates a positive gradient that recruits more macrophages to an area, stimulates mitoses of macrophages, and the release of histamine by Mastocytes.

In this toy model, bacteria can evolve to try to avoid the immune system by either increasing the speed with which they move while sacrificing feed efficiency or vice-versa, depending on the environment determined by the infection state. Macrophages do not evolve but can have two different origins, native from the tissue (Mitotic macrophages) or recruited from the bloodstream (Blood macrophages), and play a crucial role in controlling the liberation of histamine by the mastocytes.

In the fight against an infection, the interaction between different defense mechanisms creates very interesting patterns and defense strategies, some of which can be explored in a simplified way in this model.

## HOW IT WORKS

#### Moviment
There are three main types of agents in this model, which are bacteria (visualized as colored ovals), mastocytes (visualized as big red doted circles), and macrophages (visualized as colored spiky circles with a black dot).

Bacteria wander the tissue randomly, destroying and eating epithelium and endothelial cells (visualized as brow and red patches, respectively) to gain energy as they move. In the absence of a cytokine gradient, macrophages move randomly in the healthy tissue and receive nutrition. When macrophages detect cytokines, they move toward the positive cytokine gradient. Mastocytes are fixed cells that do not die, multiply or need to feed. Bacteria and macrophages will die if they run out of energy, for example, by moving extensively on tissue that is severally damaged and low in nutrients.

Bacteria speed defines how fast they move, and feed efficiency determines how much energy the bacteria spend in each clock tick. Increasing speed is an effective way for bacteria to evade the immune defenses, but mutations that increase speed also reduce the feed efficiency as faster movement requires more energy per step. As a result, faster bacteria are more efficient to evade the immune but are more likely to die by starvation.

#### Multiplication and mutations
Bacteria will divide if they accumulate enough energy. When bacteria divide, they have a chance of mutating the speed and feed efficiency. The mutations are transmitted to the next generations. Bacteria can have different colors to express their level of mutation::

* Light brown: slow speed, high feed efficiency.
* Green: medium speed, medium feed efficiency.
* Light blue: fast speed, low feed efficiency.

Macrophages have a chance to undergo mitosis if they are amidst a large concentration of cytokines, originating pink macrophages (mitotic macrophages). Cytokines that fall in the blood vessel can also recruit macrophages from other tissues (blood macrophages) that are red. The two types of macrophages (pink and red) are functionally identical, and the color difference serves to track the type of defense (local or systemic) more active in each stage of the infection.


#### Molecular mediators
Cytokines are released in small quantities when bacteria destroy healthy tissue and at large amounts when a macrophage phagocyte a bacterium. They are represented by the white-pinkish flashes released on tissue patches. Usually, the release of cytokines by dying tissue is enough to recruit nearby macrophages but not sufficient to trigger mastocytes' histamine release. The aim is to represent the crucial role that phagocytosis play in mediating other immune responses.

Histamine (small red dots) released by mastocytes has a short duration on the tissue, but their role in the immune response is paramount. When bacteria feed off a patch that contains active histamine, it loses its mobility and becomes an easy target for macrophages or death by starvation.

#### Agents deaths

Macrophages die when they starve by moving throughout damaged tissue. Bacteria die when they are phagocyted by macrophages or die of starvation by moving in damaged tissue. Histamine disappears after the set duration time of its effect.

## HOW TO USE IT

This model can be used to observe the interaction between immune cells and their immune mediators and possible outcomes of an infectious process. 

### Buttons
#### Setup
Initializes variables and creates the initial bacteria, macrophages, and mastocytes. 
#### Go
Runs the model
### Sliders and Switches 
#### Initial-mastocytes
This slider controls the number of mastocytes in the tissue at the beginning of the simulation.
#### Number-ini-bacteria
This slider controls the number of bacteria infecting the tissue at the beginning of the simulation.
#### Initial-num-macrophages
This slider controls the number of macrophages in the beginning of the simulation.
#### Histamine-effect-duration
This slider defines for how long the released histamine will stay active in the tissue
#### Initial-bacterias-speed
This slider defines the initial bacteria speed and its correspondent feed efficiency   
#### Macrophage-speed
This slider defines the fixed macrophages speed
#### Histamine-release-threshold
This slide determines the minimum concentration of cytokines needed to trigger the release of histamine by mastocytes.
#### Mutation?
Switch on and off the possibility of bacteria to suffer mutation.

### Plots and monitors

#### Bacteria avg speed - Monitor
This monitor shows the current average bacterial speed.

#### Bacteria avg speed - Plot
This plot shows the evolution of bacterial speed over time.

#### Bacteria avg feed efficiency
This plot shows the evolution of bacterial feed efficiency over time as a result of mutation and selection pressure.

#### Tissue population of bacteria and immune cells
Plots the total cell number for each type of cell (bacteria from the 3 possible types and macrophages from the 2 different origins) 

#### Anaphylactic bursts
Plots the number of active histamine molecules over time.

#### Tissue Health
Plots the mean amount of food available for bacteria and macrophages. The measurement of tissue food can be understood as a proxy for its health status


## THINGS TO NOTICE


When clicking in "go" take some time to watch what is happening in the simulation. Notice how the cytokines signals draw macrophages to where the bacteria are. After successful phagocytosis, observe how the macrophages amplify the cytokines signal triggering other responses such as the mitosis and recruitment of other macrophages and the bursts of histamine by mastocytes. Is this kind of interaction and amplification of signals a common feature in the immune responses? In a living organism, is it true that the larger the immune response to infection, the better?

After a while of playing with the simulation, you will probably observe scenarios where the immune system subsides the infection and others where the infection becomes chronic. What are the relevant factors that determine these two possible outcomes? Is it possible to quell the infection by allowing either macrophages or mastocytes to defend the tissue alone? What are the conditions for that? Is it viable in a living organism?

The macrophages and bacteria depend on living tissue to thrive. Both feed on the nutrients available there. After the installation of a chronic infection, what happens with the overall tissue health (available food)? Does that favor bacteria or macrophages? Does it resemble what happens in reality?

As time goes on, observe how the bacterial population changes and how the number of defense cells and histamine release fluctuates. Is there a relationship between tissue health, histamine releases, and the number of macrophages?


## THINGS TO TRY

Try changing the initial number of bacterias (bacterial load) to see how that affects the speed and probability of a severe infection.

Another interesting possibility is to observe how natural selection affects the predominant bacteria. Try to switch on and off the mutation knob to see how that affects the chances of the infection to thrive. 

Play with the different histamine characteristics (release threshold and duration). 

## EXTENDING THE MODEL

Try adding other immune cells and signaling molecules such as lymphocytes and interleukins, respectively. 

## DISCLAIMER

This model was developed as a course requirement. The focus was to develop skills and understanding of agent-based modeling. Therefore,  the data, the description of the interaction between cells, and the biological variables mentioned here are by no means validated. Any conclusion about bacterial infections taken from this simulation will probably be incomplete or wrong.

## CREDITS AND REFERENCES

Code in this model made use of several solutions found in the models below:

* Woods, P. and Wilensky, U. (2019). NetLogo CRISPR Ecosystem model. http://ccl.northwestern.edu/netlogo/models/CRISPREcosystem. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Wilensky, U. (1997). NetLogo Ants model. http://ccl.northwestern.edu/netlogo/models/Ants. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Dunham, G., Tisue, S. and Wilensky, U. (2004). NetLogo Erosion model. http://ccl.northwestern.edu/netlogo/models/Erosion. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Alves, Marcos (2021).  NetLogo Bacterial Infection Model.  https://github.com/mppalves/NetLogo_Bacterial_Infection_Model.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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

macrophage
true
0
Polygon -7500403 true true 60 60 30 105 45 165 30 195 75 240 120 255 180 240 210 210 240 180 240 150 240 120 225 75 195 75 180 45 120 45 90 45 60 60
Circle -16777216 true false 73 88 92
Line -7500403 true 225 180 255 180
Line -7500403 true 45 195 15 195
Line -7500403 true 165 225 195 255
Line -7500403 true 165 60 180 30
Line -7500403 true 75 75 45 60

mastocyte
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
