First, use file: COMMON.md in the parent folder for general mandatory and theoretical principles that need to be applied to build an application.

Then, create a golang application to parse a JWT token per specs below.

Input parameters define below passed as arguments:
  1- access token passed as a string (-token-string)
  2- access token passed as file (-token-file)
  3- if environment variable JWT_TOKEN is defined and -token-env is passed, get the token from the environment. #1, #2, #3 are mutually exclusive, if multiple are specified, return an error
  4- output format (-output-format) - Can be JSON, CSV or XML
  5- outfile file name (-output-file) - full path of output, with correct extension per format defined in #3
  6- if a config file is passed with -config <full path of config.json>. It needs to be a sole argument. If any of arguments #1 .. #4 are present, returns an error
  7- if -output-format or outputFormat (config) is not specified, default to JSON. if -output-file or outputFile (config) is not specified, default to claims.json in the current folder
  8- in the config.json file, add a tokenType field, with values: string, file, environment.
       + If string, the value of jwtToken is that string.
	   + If file, the value of jwtToken is the fully qualified filename, in that case make sure to read the content of that file.
       + If environment, the value of jwtToken is the name of the environment variable to read the value from, by default JWT_TOKEN. Please think, plan, then show me the plan before coding for approval

Structure of config.json:
{                                                                                                                           │
  "jwtToken": "your_jwt_token_string_or_file_path_or_env_var_name",
  "tokenType": "string", // Can be "string", "file", or "environment"                                                       │
  "outputFormat": "JSON", // Can be "JSON", "CSV", or "XML" (optional, defaults to JSON)
  "outputFile": "full_path_of_output_file>", // Full path of output file (optional, defaults to claims.<format_extension>)
  "convertEpoch": true, // Boolean, whether to convert epoch timestamps to human-readable format (default false)
  "silentExec": false, // Boolean, whether to suppress all output messages (default false)
  "maxTokenSizeMB": 1, // Integer, Maximum JWT token size in MB (default 1)
  "maxOutputSizeMB": 100 // Integer, Maximum formatted output size in MB (default 100)
}
