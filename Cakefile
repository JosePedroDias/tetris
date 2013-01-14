{print} = require 'sys'
{spawn} = require 'child_process'



cArgs = ['-c', '-o', 'lib', 'src']
wArgs = cArgs.slice()
wArgs.unshift '-w'



# option '-o', '--output [DIR]', 'output dir'
#options.output or 



task 'sbuild', 'Build lib/ from src/', ->
  c = spawn 'coffee', cArgs
  c.stderr.on 'data', (d) -> process.stderr.write d.toString()
  c.stdout.on 'data', (d) -> print d.toString()
  print wArgs



task 'watch', 'Watch src/ for changes', ->
  c = spawn 'coffee', wArgs
  c.stderr.on 'data', (d) -> process.stderr.write d.toString()
  c.stdout.on 'data', (d) -> print d.toString()



### NOT WORKING
task 'open', 'Open index.html', ->
  spawn 'open', 'index.html'
  invoke 'watch'###
