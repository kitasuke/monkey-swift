import Repl

print("Hello! This is the Monky programming language!")
print("Feel free to type in commands")

Repl.start(with: readLine() ?? "")
