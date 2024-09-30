# example.py

def calculate_area(l, b):
    # Calculates area of rectangle
    area = l * b
    return area
print(calculate_area(5, 10))

def add_numbers(a, b):
    return a+b

def find_largest(numbers):
  if len(numbers) == 0:
        return None
  largest = numbers[0]
  for num in numbers:
    if num > largest:
      largest = num
  return largest

def SayHello():
  print("Hello, World!")

def fibonacci(n):
    a, b = 0, 1
    result = []
    while a < n:
        result.append(a)
        a, b = b, a + b
        return result

