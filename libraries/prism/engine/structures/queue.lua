--- A basic FIFO (First In, First Out) queue implementation.
--- @class Queue : Object
--- @overload fun(): Queue
local Queue = prism.Object:extend("Queue")

--- Initializes a new Queue instance.
function Queue:__new()
   self.queue = {}
   self.first = 1
   self.last = 0
end

--- Adds an element to the end of the queue.
--- @param value any The value to be added to the queue.
function Queue:push(value)
   self.last = self.last + 1
   self.queue[self.last] = value
end

--- Removes and returns the element from the start of the queue.
--- @return any -- The value at the start of the queue.
function Queue:pop()
   local value = self.queue[self.first]
   if value then
      self.queue[self.first] = nil
      self.first = self.first + 1

      return value
   end
end

--- Checks if the queue is empty.
--- @return boolean -- True if the queue is empty, false otherwise.
function Queue:empty()
   return self.first > self.last
end

--- Returns the element at the start of the queue without removing it.
--- @return any -- The value at the start of the queue.
function Queue:peek()
   return self.queue[self.first]
end

--- Removes all elements from the queue.
function Queue:clear()
   self.queue = {}
   self.first = 1
   self.last = 0
end

--- Checks if the queue contains a specific value.
--- @param value any The value to check for.
--- @return boolean -- True if the value is in the queue, false otherwise.
function Queue:contains(value)
   for i = self.first, self.last do
      if self.queue[i] == value then return true end
   end
   return false
end

--- Returns the number of elements in the queue.
--- @return number -- The size of the queue.
function Queue:size()
   return self.last - self.first + 1
end

--- Removes the first occurrence of the specified value from the queue.
--- @param value any The value to be removed from the queue.
--- @return boolean -- True if the value was removed, false otherwise.
function Queue:remove(value)
   for i = self.first, self.last do
      if self.queue[i] == value then
         -- Shift elements to fill the gap
         for j = i, self.last - 1 do
            self.queue[j] = self.queue[j + 1]
         end
         self.queue[self.last] = nil
         self.last = self.last - 1
         return true
      end
   end
   return false
end

-- Unit tests
-- luacheck: push ignore

-- Test 1: Create a new Queue and check it is empty
local queue = Queue()
assert(queue:empty(), "Test 1 Failed: New queue should be empty")

-- Test 2: Add an element and check the queue is not empty
queue:push(1)
assert(not queue:empty(), "Test 2 Failed: Queue should not be empty after push")

-- Test 3: Remove an element and check the queue is empty again
local value = queue:pop()
assert(value == 1, "Test 3 Failed: Pop should return the value pushed")
assert(queue:empty(), "Test 3 Failed: Queue should be empty after pop")

-- Test 4: Check peek returns the first element without removing it
queue:push(2)
queue:push(3)
assert(queue:peek() == 2, "Test 4 Failed: Peek should return the first element without removing it")
assert(queue:size() == 2, "Test 4 Failed: Size should be 2 after two pushes")

-- Test 5: Fill the queue and check that elements come out in the correct order
local queue = Queue()
local testData = { 5, 2, 8, 9, 1, 3, 7, 6, 4 }
for i, v in ipairs(testData) do
   queue:push(v)
end

for i, v in ipairs(testData) do
   assert(
      queue:pop() == v,
      "Test 5 Failed: The order of elements coming out of the queue is incorrect"
   )
end

-- Test 6: Interleave pushes and pops
queue:push(1)
assert(
   queue:pop() == 1,
   "Test 6 Failed: Queue should return the same element after a push-pop cycle"
)
queue:push(2)
queue:push(3)
assert(queue:pop() == 2, "Test 6 Failed: Queue should return the first pushed element")
queue:push(4)
assert(queue:pop() == 3, "Test 6 Failed: Queue should return the second pushed element")

-- Test 7: Clear the queue and check it is empty
queue:clear()
assert(queue:empty(), "Test 7 Failed: Queue should be empty after clear")

-- Test 8: Check if the queue contains specific elements
queue:push(5)
queue:push(10)
queue:push(15)
assert(queue:contains(10), "Test 8 Failed: Queue should contain 10")
assert(not queue:contains(20), "Test 8 Failed: Queue should not contain 20")

-- luacheck: pop

return Queue
