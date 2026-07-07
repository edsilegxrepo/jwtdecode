General principles:

1- Before coding, think through this step by step and help me plan the entire application architecture.
2- IMPORTANT: Do not rely on replace tool for complex, multi-line changes, as it causes repeated failures and endless loops, use write_file
3- Before making any change, backup the existing file with a timestamp suffix
4- Use the 4 following tools (in this order) to validate the code generated at every step, and systematically before building: go fmt, go vet, golangci-lint, govulncheck
5- For a complex problem, decompose in smaller units, and validate each before re-assembling into the final solution
6- Use the following logic to build (use version.txt to get the version, increment by one at every build, and append a YYYYMMDD datestamp to it). Example: go build -ldflags "-s -w -X main.version=0.0.1-20250830" -o binary.exe
   The second build will be 0.0.2 .. 0.0.9, then 0.1.0 .. 0.1.9, then 0.2.0 .. 0.2.9, etc
   CGO_ENABLED=0 needs to be enforced to make the binary portable (static builds)
7- Use the fillowing standard arguments:
     -version to display the current application version
     -silent to run the application withn no output
     -config <file> to use a JSON formatted property file to define application parameters
8- Use always the correct end of line termination depending on the platform (\r\n for Windows, \n for Linux)
9- Always think, use tools as needed, then plan, then communicate the plan for approval. Do not code right away.
10- After the code is generated, do a deep analysis of the code base produced for recommendations and improvements. They all need to be approved.
11- Perform a security analysis and review, provide security recommendations. Make sure all user inputs are properly sanitized and secured to avoid any malicious injections
12- Do not autocommit to remote git repository. All git push operations must be explicitly requested and confirmed
13- Use TZ US/Central for all date operations
