import csv
import os

class ScrabbleTile:
    def __init__(self, letter, value, quantity):
        self.letter = letter
        self.value = value
        self.quantity = quantity

scrabble = {}

script_dir = os.path.dirname(__file__)
abs_file_path = os.path.join(script_dir, "../../data/scrabble-v1.csv")
with open(abs_file_path, 'r') as csvfile:
    reader = csv.reader(csvfile)
    next(reader)
    for row in reader:
        letter = row[0].strip().lower()
        value = int(row[1].strip())
        quantity = int(row[2].strip())
        scrabble[letter] = ScrabbleTile(letter, value, quantity)
