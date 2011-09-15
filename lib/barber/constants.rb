# Some amount of eyeballing will always be required in order for this to work;
# multiple composition methods will allow for some flexibility in determining
# the bounding box
COMPOSITIONS = {
  :default  => {method: '-compose multiply -flatten -blur 4 -normalize', color: 'gray'},
  :average  => {method: '-average', color: 'lightgray'},
}
