# "Another" Language Compiler

This repository contains a compiler for the "Another" language, which is designed to compile into C code. The "Another" language introduces custom data types, operators, and expressions while resembling C syntax.

## Language Features

- **Data Types**: Two data types are available: `int` and `arr`, a dynamic array of integers.
- **Constants/Literals**: Integers and integer arrays can be used as constants.
- **Variable Definition**: Declare variables using `int` or `arr`.
- **Operators**: Custom operators such as `@` for dot-product and `:` for indexing.
- **Expressions**: Mathematical expressions, variable references, and array operations.
- **Control Structures**: Supports `if` conditionals and `while` loops.
- **Printing**: The `print` statement outputs values.
- **Variable Naming**: Follows C-like rules for variable naming.

## Compilation and Usage

1. Ensure required tools (e.g., Lex and Yacc(Bison)) are installed.
2. Clone this repository and navigate to it:

    ```bash
    git clone https://github.com/shaharariel95/AnotherLanguageCompiler.git
    cd another-language-compiler
    ```

3. Build the compiler:

    ```bash
    make
    ```

4. Process "Another" language source files:

    ```bash
    ./another.exe < inputFile.another
    ```

5. Compile the generated C code:

    ```bash
    gcc program.c -o program
    ```

6. Run the compiled program:

    ```bash
    ./program
    ```

## Example Program

An example "Another" language program is provided in `example.another`. Compile and execute it to understand the language better.

## Contributions

Contributions are welcome! Feel free to enhance the compiler, improve documentation, or add new features. Submit a pull request with your changes, or raise issues for discussions.

For questions or assistance, contact the maintainers or open an issue in the repository.

Happy coding with the "Another" language!
