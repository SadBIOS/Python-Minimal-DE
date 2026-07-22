import sys
import subprocess

print("Python version:")
print(sys.version)

print("\nInstalled packages:")
print("-" * 40)

packages = subprocess.check_output(
    [sys.executable, "-m", "pip", "list"],
    text=True
)

print(packages)