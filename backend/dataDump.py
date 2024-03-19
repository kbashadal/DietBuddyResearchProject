from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class FoodCategory(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)
    
import csv

def load_unique_food_categories():
    unique_categories = set()
    with open('archive-4/calories.csv', mode='r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            unique_categories.add(row['FoodCategory'])

    return unique_categories
def insert_food_categories_into_db():
    unique_categories = load_unique_food_categories()
    for category_name in unique_categories:
        existing_category = FoodCategory.query.filter_by(name=category_name).first()
        if not existing_category:
            new_category = FoodCategory(name=category_name)
            db.session.add(new_category)
    
    db.session.commit()