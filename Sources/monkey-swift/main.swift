import Foundation
import Repl

private let prompt = ">> "

print("Hello! This is the Monkey programming language!")
print("Feel free to type in commands")

while(true) {
    print(prompt, terminator: "")
    Repl.start(with: readLine() ?? "")
}
