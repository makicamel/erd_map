# frozen_string_literal: true

ErdMap.queue = Queue.new
ErdMap.py_call_modules = ErdMap::PyCallModules.new

Thread.new do
  task_queue = ErdMap.queue
  loop do
    task_queue.pop.call
  end
end
