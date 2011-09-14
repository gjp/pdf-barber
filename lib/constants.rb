# Some amount of eyeballing will always be required in order for this to work;
# multiple composition methods will allow for some flexibility in determining
# the bounding box
COMPOSITIONS = {
  :default  => ['-compose multiply -flatten -blur 4 -normalize -fuzz 50% -fill red',
                'gray'],

  :average  => ['-average -fuzz 50% -fill red',
                'lightgray'],

  :colorize => ['-fill white -colorize 75% -compose multiply -flatten -blur 1 -normalize -fuzz 50%',
                'gray']
}
