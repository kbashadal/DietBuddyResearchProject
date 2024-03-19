from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import IntegrityError
from flask_bcrypt import Bcrypt
import base64
import uuid
import os
import csv
import pandas as pd
import joblib
import requests
from werkzeug.utils import secure_filename
import re
import numpy as np

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:postgres@localhost/dietBuddy'
UPLOAD_FOLDER = 'static/profile_pics'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)

class MealType(db.Model):
    __tablename__ = 'meal_type'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True, nullable=False)

    def __repr__(self):
        return f'<MealType {self.name}>'

class UserMeals(db.Model):
    __tablename__ = 'user_meals'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    item_id = db.Column(db.Integer, db.ForeignKey('food_items.id'), nullable=False)
    meal_type_id = db.Column(db.Integer, db.ForeignKey('meal_type.id'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    time = db.Column(db.Time, nullable=False)
    weight = db.Column(db.Float, nullable=True)  # Weight in grams
    volume = db.Column(db.Float, nullable=True)  # Volume in milliliters
    calories = db.Column(db.Float, nullable=True)  # Calories in calories
    caffeine = db.Column(db.Float, nullable=True)  # Caffeine in mg


    # Relationships
    user = db.relationship('User', backref=db.backref('user_meals', lazy=True))
    food_item = db.relationship('FoodItems', backref=db.backref('user_meals', lazy=True))
    meal_type = db.relationship('MealType', backref=db.backref('user_meals', lazy=True))

    def __repr__(self):
        return f'<UserMeals {self.user_id} {self.item_id} {self.meal_type_id}>'

class FoodCategory(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)

    
class FoodItems(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    FoodItemName = db.Column(db.String(255), nullable=False)
    volume_ml = db.Column(db.Float, nullable=True)  # Volume in milliliters
    Calories = db.Column(db.String(255), nullable=True)
    caffeine_mg = db.Column(db.Float, nullable=True)  # Caffeine content in milligrams
    Cals_per100grams = db.Column(db.String(255), nullable=True)
    KJ_per100grams = db.Column(db.String(255), nullable=True)
    
    # Foreign key to reference FoodCategory
    category_id = db.Column(db.Integer, db.ForeignKey('food_category.id'), nullable=False)
    # Relationship (optional for easier access)
    category = db.relationship('FoodCategory', backref=db.backref('food_items', lazy=True)) 
    


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email_id = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)  # Store the hashed password
    full_name = db.Column(db.String(50), nullable=False)
    height = db.Column(db.Float, nullable=False)
    weight = db.Column(db.Float, nullable=False)
    date_of_birth = db.Column(db.Date, nullable=False)
    profile_pic = db.Column(db.String(255), nullable=True)  # Add this line for profile picture
    bmi = db.Column(db.Float, nullable=True)  # Add this line for BMI
    bmi_category = db.Column(db.String(50), nullable=True)  # Add this line for BMI category




    def __repr__(self):
        return f'<User {self.email_id}>'

    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')

    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)
    
def determine_bmi_category(bmi):
    if bmi < 18.5:
        return 'Underweight'
    elif 18.5 <= bmi <= 24.9:
        return 'Normal Weight'
    elif 25.0 <= bmi <= 29.9:
        return 'Overweight'
    else:
        return 'Obese'

@app.route('/register', methods=['POST'])
def register_user():
    data = request.json
    height_in_meters = int(data['height']) / 100
    bmi = float(data['weight'] )/ (height_in_meters ** 2)
    bmi_category = determine_bmi_category(bmi)  # Determine the BMI category  
    # insert_food_items()
    if 'ProfilePic' in data:
        profile_pic_data = data['ProfilePic']
        padding_needed = len(profile_pic_data) % 4
        if padding_needed:  # padding_needed is not 0
            profile_pic_data += "=" * (4 - padding_needed)
        
        profile_pic_bytes = base64.b64decode(profile_pic_data)
        filename = f"{uuid.uuid4()}.jpeg"  # Assuming the image is a PNG
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        with open(file_path, 'wb') as file:
            file.write(profile_pic_bytes)
        
        
    try:
        filename = "None"
        new_user = User(email_id=data['email'], full_name=data['fullName'],
                        height=height_in_meters, weight=data['weight'], date_of_birth=data['dateOfBirth'],profile_pic=filename,
                        bmi=bmi, bmi_category=bmi_category)
        new_user.set_password(data['password'])  # Set the hashed password
        db.session.add(new_user)
        db.session.commit()
        print("new user added",new_user)
        return jsonify({'message': 'User registered successfully!'}), 201
    except IntegrityError:
        db.session.rollback()
        return jsonify({'message': 'This email is already registered.'}), 409

@app.route('/login', methods=['POST'])
def login_user():
    data = request.json
    user = User.query.filter_by(email_id=data['email']).first()
    if user and user.check_password(data['password']):
        return jsonify({'message': 'Login successful!'}), 200
    else:
        return jsonify({'message': 'Invalid email or password'}), 401
@app.route('/add_user_meals', methods=['POST'])
def add_user_meals():
    data = request.json  # Get the JSON data sent to the endpoint
    
    # Check if the data is a list of meals
    if not isinstance(data, list):
        return jsonify({'message': 'Input should be a list of meal records.'}), 400
    
    new_meals = []  # List to hold the new UserMeals objects before bulk insert
    
    for meal in data:
        user_email = meal.get('user_email')
        food_item_name = meal.get('food_item_name')
        meal_type_name = meal.get('meal_type_name')
        date = meal.get('date')
        time = meal.get('time')
        if 'Caffeine' in meal.keys():
            model = joblib.load('caffeine_calories_predictor_rf.pkl')
            volume = meal.get("Volume (ml)")
            Caffeine = meal.get("Caffeine")            
            input_df = pd.DataFrame({
                'drink': [food_item_name],
                'Volume (ml)': [volume],
                'Caffeine (mg)': [Caffeine]
            })   
            weight = float(0)
                 
        elif "weight(gms)" in meal.keys():
            model = joblib.load('fooditem_calories_predictor.pkl')
            weight = meal.get("weight(gms)")   
            input_df = pd.DataFrame({
                'FoodItem':[food_item_name],
                'per100grams':[weight]  })
            volume = float(0)
            Caffeine = float(0)
        predicted_calories = model.predict(input_df)[0]     
        user = User.query.filter_by(email_id=user_email).first()
        food_item = FoodItems.query.filter_by(FoodItemName=food_item_name).first()
        meal_type = MealType.query.filter_by(name=meal_type_name).first()
        if user and food_item and meal_type:
            # Create a new UserMeals object with the found entities and add it to the list
            new_meal = UserMeals(user_id=user.id, item_id=food_item.id, meal_type_id=meal_type.id, date=date, time=time,
                                 weight = float(weight),volume = float(volume),calories=float(predicted_calories),caffeine=float(Caffeine))
            new_meals.append(new_meal)
        else:
            # Handle the case where user, food item, or meal type is not found
            print(f"Error: Could not find User with email {user_email}, FoodItem with name {food_item_name}, or MealType with name {meal_type_name}.")
    
    # Insert all new meals into the database in a bulk operation
    
    try:
        db.session.add_all(new_meals)
        db.session.commit()
        return jsonify({'message': f'{len(new_meals)} meals added successfully.'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Failed to add meals.', 'error': str(e)}), 500

@app.route('/user_meals_summary_by_email', methods=['GET'])
def user_meals_summary_by_email():
    email_id = request.args.get('email_id')
    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400

    # Find user by email_id
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Query to fetch user meals and join with MealType to categorize them
    print("user",user)
    user_meals = db.session.query(
        UserMeals, MealType.name.label('meal_type_name')
    ).join(MealType, UserMeals.meal_type_id == MealType.id
    ).filter(UserMeals.user_id == user.id).all()

    if not user_meals:
        return jsonify({'message': 'No meals found for the given user email.'}), 404

    # Summarize calories by meal type
    summary = {}
    for user_meal, meal_type_name in user_meals:
        if meal_type_name not in summary:
            summary[meal_type_name] = 0
        summary[meal_type_name] += round(user_meal.calories,2) if user_meal.calories else 0
    print("summary",summary)
    return jsonify({'email_id': email_id, 'calories_summary_by_meal_type': summary}), 200    
    
@app.route('/food_items_by_category/<category_name>', methods=['GET'])
def get_food_items_by_category(category_name):
    print("category_name", category_name)
    # Use distinct() to fetch only unique records based on FoodItemName
    food_items = FoodItems.query.join(FoodCategory).filter(FoodCategory.name == category_name).distinct(FoodItems.FoodItemName).all()
    all_food_items = [{'id': item.id, 'name': item.FoodItemName} for item in food_items]
    if all_food_items:
        return jsonify(all_food_items), 200
    else:
        return jsonify({'message': 'No food items found for the given category.'}), 404
@app.route('/food_categories', methods=['GET'])
def get_food_categories():
    categories = FoodCategory.query.all()
    categories_list = [{'id': category.id, 'name': category.name} for category in categories]
    return jsonify(categories_list)    
@app.route('/predictdrink', methods=['POST'])
def predictdrink():
    model = joblib.load('caffeine_calories_predictor_rf.pkl')
    data = request.get_json(force=True)
    print("data",data)
    # Prepare the input data frame
    input_df = pd.DataFrame({
        'drink': [data['drink']],
        'Volume (ml)': [data['Volume (ml)']],
        'Caffeine (mg)': [data['Caffeine (mg)']]
    })
    prediction = model.predict(input_df)
    print("prediction",prediction)
    return jsonify({'calories': prediction[0]})

@app.route('/predictNonDrink', methods=['POST'])
def predictNonDrink():
    model = joblib.load('fooditem_calories_predictor.pkl')
    data = request.get_json()
    print("data",data)
    # Assuming the input is a list of food items    
    input_df = pd.DataFrame({
        'FoodItem': [data['FoodItem']],
        'per100grams': [data['per100grams']]    })
    predictions = model.predict(input_df)
    print("predictions",predictions)
    return jsonify({'calories': predictions[0]})

@app.route('/suggestExecise', methods=['POST'])
def predict_exercises():
    # Extract 'calories' from the request
    model = joblib.load('calories_based_workout_predictor.pkl')

    data = request.get_json()
    calories = data.get('calories')
    
    # Check if calories is provided
    if calories is None:
        return jsonify({'error': 'Missing parameter: calories'}), 400

    # Create a DataFrame with calories as the only column
    input_df = pd.DataFrame({'calories': [calories]})
    
    # Make prediction
    prediction = model.predict_proba(input_df)
    
    # Assuming the model has a method to return class probabilities
    top_3_indices = prediction.argsort()[0][-3:][::-1]
    top_3_workouts = [model.classes_[i] for i in top_3_indices]
    
    return jsonify({'top_3_suggestions': top_3_workouts})

# Load the classification model
classifier = joblib.load('exercise_classifier.pkl')

# Function to load regressor models for the top exercises
def load_regressors(top_exercises):
    regressors = {}
    for exercise in top_exercises:
        regressors[exercise] = joblib.load(f'{exercise}_time_regressor.pkl')
    return regressors
@app.route('/suggestExerciseWithTime', methods=['POST'])
def predictExerciseWithTime():
    # Extract 'calories' from the request
    data = request.get_json()
    calories = data.get('calories')
    
    if calories is None:
        return jsonify({'error': 'Missing parameter: calories'}), 400
    
    # Assuming the classifier expects a DataFrame with a 'calories' column
    # and you have preprocessed your data accordingly during model training
    input_df = pd.DataFrame({'calories': [calories], 'time': [0]})  # Dummy 'time' value, not used by the classifier
    
    # Predict the top 3 workout types
    probs = classifier.predict_proba(input_df)[0]
    classes = classifier.classes_
    top_3_indices = np.argsort(probs)[-3:][::-1]  # Indices of top 3 classes
    top_3_exercises = classes[top_3_indices]
    
    # Load regressor models for the top 3 exercises
    regressors = load_regressors(top_3_exercises)
    
    # Estimate time required for each of the top 3 exercises to burn the specified calories
    exercise_time_estimates = []
    for exercise in top_3_exercises:
        regressor = regressors[exercise]
        # Assuming regressor expects a DataFrame with a 'calories' column
        time_estimate = regressor.predict([[calories]])[0]  # Get time estimate
        exercise_time_estimates.append({'exercise': exercise, 'time': time_estimate})
    
    return jsonify({'top_3_exercises_with_time': exercise_time_estimates})



@app.route('/predictFromImage', methods=['POST'])
def predictFromImage():
    if 'image' not in request.files:
        return jsonify({'error': 'No image part'}), 400
    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No selected image'}), 400
    if file:
        # Save the file to the UPLOAD_FOLDER
        filename = secure_filename(file.filename)  # Import secure_filename from flask
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)

        api_user_token = "17db64859aabf9f3620cbe9c5b4f30375228d329"
        headers = {'Authorization': 'Bearer ' + api_user_token}

        # Single/Several Dishes Detection
        url = 'https://api.logmeal.es/v2/image/segmentation/complete'
        with open(file_path, 'rb') as img_file:
            segmentation_resp = requests.post(url, files={'image': img_file}, headers=headers)

        print("segmentation_resp", segmentation_resp)
        if segmentation_resp.status_code != 200:
            return jsonify({'error': 'Failed to segment image'}), segmentation_resp.status_code

        # Nutritional information
        url = 'https://api.logmeal.es/v2/recipe/nutritionalInfo'
        nutritional_info_resp = requests.post(url, json={'imageId': segmentation_resp.json()['imageId']}, headers=headers)
        print(nutritional_info_resp)
        if nutritional_info_resp.status_code != 200:
            return jsonify({'error': 'Failed to get nutritional information'}), nutritional_info_resp.status_code
        nutritional_info_resp_jasn = nutritional_info_resp.json()
        caloires_predicted = {}
        caloires_predicted[nutritional_info_resp_jasn['foodName'][0]] = nutritional_info_resp_jasn["nutritional_info"]["calories"]
        os.remove(file_path)
        return jsonify(caloires_predicted)
    
@app.route('/alternate_food', methods=['GET'])
def get_alternate_food():
    try:
        target_calories = float(request.args.get('calories'))
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid or missing calories parameter'}), 400

    all_food_items = FoodItems.query.all()
    calorie_differences = []
    seen_calories = set()  # Set to track unique calorie values

    for item in all_food_items:
        # Extract numeric part from Cals_per100grams
        match = re.search(r'(\d+)', item.Cals_per100grams)
        if match:
            item_calories = float(match.group(1))
            if item_calories not in seen_calories:
                seen_calories.add(item_calories)  # Mark this calorie value as seen
                if item_calories < target_calories:
                    # Calculate the difference and store it along with the item
                    calorie_differences.append((item, target_calories - item_calories))

    # Sort items by their calorie difference in ascending order
    calorie_differences.sort(key=lambda x: x[1])

    # Select the top 3 items with the smallest difference
    top_3_alternates = [item[0] for item in calorie_differences[:3]]

    if top_3_alternates:
        return jsonify([{
            'FoodItemName': item.FoodItemName,
            'Cals_per100grams': item.Cals_per100grams
        } for item in top_3_alternates]), 200
    else:
        return jsonify({'message': 'No alternate food items found close to the target calories'}), 404
    
def insert_unique_categories():
    unique_categories = set()
    # Extract categories from caffeine.csv
    with open('archive-4/caffeine.csv', mode='r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            unique_categories.add(row['FoodCategory'])
    # Extract categories from calories.csv
    with open('archive-4/calories.csv', mode='r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            unique_categories.add(row['FoodCategory'])
    
    for category_name in unique_categories:
        existing_category = FoodCategory.query.filter_by(name=category_name).first()
        if not existing_category:
            new_category = FoodCategory(name=category_name)
            db.session.add(new_category)
    db.session.commit()

def insert_food_items():
    # Ensure categories are inserted first
    # insert_unique_categories()
    
    # Insert items from caffeine.csv
    with open('archive-4/caffeine.csv', mode='r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            category = FoodCategory.query.filter_by(name=row['FoodCategory']).first()
            if category:
                new_food_item = FoodItems(
                    FoodItemName=row['drink'],
                    volume_ml=float(row['Volume (ml)']) if row['Volume (ml)'] else 0,
                    Calories=row['Calories'] if row['Calories'] else "0",
                    caffeine_mg=float(row['Caffeine (mg)']) if row['Caffeine (mg)'] else 0,
                    Cals_per100grams=calories_per_100g(float(row['Volume (ml)']), float(row['Calories'])),  # Default value, adjust if needed
                    KJ_per100grams="0",  # Default value, adjust if needed
                    category_id=category.id
                )
                db.session.add(new_food_item)
    
    # Insert items from calories.csv
    with open('archive-4/calories.csv', mode='r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            category = FoodCategory.query.filter_by(name=row['FoodCategory']).first()
            Cals_per100grams=row['Cals_per100grams'] if row['Cals_per100grams'] else "0",
            
            if 'cal' in Cals_per100grams:
                Cals_per100grams = Cals_per100grams.replace('cal', '')[0]
            print("Cals_per100grams",Cals_per100grams)    
            if category:
                new_food_item = FoodItems(
                    FoodItemName=row['FoodItem'],
                    volume_ml=0,  # Default value, adjust if needed
                    Calories="0",  # Default value, adjust if needed
                    caffeine_mg=0,  # Default value, adjust if needed
                    Cals_per100grams=Cals_per100grams,#row['Cals_per100grams'] if row['Cals_per100grams'] else "0",
                    KJ_per100grams=row['KJ_per100grams'] if row['KJ_per100grams'] else "0",
                    category_id=category.id
                )
                db.session.add(new_food_item)
    with open('archive-4/menu.csv', mode='r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if 'g' in row['Serving Size']:
                match = re.search(r'\((\d+)\s*g\)', row['Serving Size'])
                value_in_grams = int(match.group(1))
                category = FoodCategory.query.filter_by(name=row['Category']).first()
                calories = int(row['Calories'])
                Cals_per100grams = (calories / value_in_grams) * 100
                if category:
                    new_food_item = FoodItems(
                        FoodItemName=row['Item'],
                        volume_ml=0,  # Default value, adjust if needed
                        Calories=str(calories),  # Default value, adjust if needed
                        caffeine_mg=0,  # Default value, adjust if needed
                        Cals_per100grams= Cals_per100grams if Cals_per100grams else "0",
                        KJ_per100grams=str(Cals_per100grams*4.184 ),  # # Conversion factor from calories to kilojoules
                        category_id=category.id
                    )
                    db.session.add(new_food_item)
    db.session.commit()
    
    
def calories_per_100g(volume_ml, calories):
  """
  This function calculates the calories per 100 grams of a food item,
  assuming a density of 1 gram per milliliter.

  Args:
      volume_ml (float): Volume of the food item in milliliters.
      calories (int): Total calories of the food item.

  Returns:
      float: Calories per 100 grams of the food item, or 0 if volume is 0.
  """
  if volume_ml == 0:
    # Handle division by zero error
    return 0
  else:
    return (calories * 100) / volume_ml
if __name__ == '__main__':
    with app.app_context():
        db.create_all()        
    app.run(debug=True)