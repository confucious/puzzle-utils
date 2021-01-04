import csv
import os

primes = []

script_dir = os.path.dirname(__file__)
abs_file_path = os.path.join(script_dir, "../../data/1000primes-v1.csv")
with open(abs_file_path, 'r') as csvfile:
    reader = csv.reader(csvfile)
    for row in reader:
        for value in row:
            prime = int(value)
            if prime not in primes:
                primes.append(prime)
