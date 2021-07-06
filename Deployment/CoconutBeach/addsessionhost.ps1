        param (
            $hostpoolName,
            $hostpoolToken,
            $downloadUrl
        )
        Invoke-WebRequest  -OutFile c:\temp\
        Expand-Archive c:\temp\configuration.zip
        & "\configuration\configuration.ps1" -hostpoolName  -RegistrationInfoToken "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijk3NkE4Q0I1MTQwNjkyM0E4MkU4QUQ3MUYzQjE4NzEyN0Y2OTRDOTkiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6ImJiZTc1Y2I4LTA5OGEtNGFlYi05ZWIxLWY5YWM1MmQwMTEzOSIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy1ldS1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLWV1LXIwLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiNzA1MDQ1MTctOWM4Yi00NDNlLTkxMzgtMGQ1ZWY1OWQ1NzNiIiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJFVSIsIm5iZiI6MTYyMzkxMjAwNCwiZXhwIjoxNjIzOTQyMTE0LCJpc3MiOiJSREluZnJhVG9rZW5NYW5hZ2VyIiwiYXVkIjoiUkRtaSJ9.UcwXrSVX9xf93EDOtWIPrj7I-HLKCgNQqjeQYkvSA2zkRtVt7EQB1NuMZyC2ysM2QcZf13QQOkitefWpoxGDgsIuP4En2Dwg21WkxQPtYyaUw9RVnW5tZ8dg3YYmW9_Jty5eff7Zccri3iDyOGl5tzUrX6hFg38GfI7cuIzyhE0ugDuh-6C441OApcKBOwWCrO88HhrQZtfbgNNJoYSyRLuBmL8x6mN8NPeuGxsAUMenRB3SYLL5jMKqU39dRCZsmGdyT2hlOsx0QOSVhzMEZvXKxIedxP34hqmE1ULfWFZ6bPndEzZ-COahCHvxdYdtae4o38BRWOKA6Dckaxseaw"
