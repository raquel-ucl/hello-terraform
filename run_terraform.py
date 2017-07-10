from python_terraform import *

t = Terraform(working_dir='/Users/raquel/workspace/self-serve/hello-terraform')
return_code, stdout, stderr = t.apply(capture_output=False)
