import datetime
import json
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
from collections import defaultdict

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://admin:wchKjb6q0uveqol3nuyXPKx32lrfHcmo@dpg-co5e3t7sc6pc73851tk0-a.oregon-postgres.render.com/deitbuddy'

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
    
class Exercise(db.Model):
    __tablename__ = 'exercise'
    id = db.Column(db.Integer, primary_key=True)
    workout_type = db.Column(db.String(255), nullable=False)

    def __repr__(self):
        return f'<Exercise {self.workout_type}>'

class UserExerciseSuggestions(db.Model):
    __tablename__ = 'user_exercise_suggestions'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    exercise_id = db.Column(db.Integer, db.ForeignKey('exercise.id'), nullable=False)
    suggested_on = db.Column(db.Date, default=datetime.date.today)
    suggested_time = db.Column(db.Float, nullable=True)  # Suggested time in minutes

    # Relationships
    user = db.relationship('User', backref=db.backref('exercise_suggestions', lazy=True))
    exercise = db.relationship('Exercise', backref=db.backref('suggested_to_users', lazy=True))

    def __repr__(self):
        return f'<UserExerciseSuggestions {self.user_id} {self.exercise_id}>'

class UserAlternateFood(db.Model):
    __tablename__ = 'user_alternate_food'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    food_item_name = db.Column(db.String(255), nullable=False)
    suggested_on = db.Column(db.Date, default=datetime.date.today)
    suggested_time = db.Column(db.Time, default=datetime.datetime.now().time)

    # Relationships
    user = db.relationship('User', backref=db.backref('alternate_food_suggestions', lazy=True))
    food_item = db.relationship('FoodItems', foreign_keys=[food_item_name], primaryjoin="UserAlternateFood.food_item_name==FoodItems.FoodItemName", backref=db.backref('suggested_to_users', lazy=True))

    def __repr__(self):
        return f'<UserAlternateFood {self.user_id} {self.food_item_name}>'

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
    suggested_calories = db.Column(db.Float, nullable=True)  # Add this line for suggested calories
    duration = db.Column(db.Float, nullable=True)
    target_weight = db.Column(db.Float, nullable=True)
    activity_level = db.Column(db.String(50), nullable=True)
    gender = db.Column(db.String(10), nullable=True)




    def __repr__(self):
        return f'<User {self.email_id}>'

    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')

    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)
   
   
class UserChatHistory(db.Model):
    __tablename__ = 'user_chat_history'
    id = db.Column(db.Integer, primary_key=True)
    email_id = db.Column(db.String(120), db.ForeignKey('user.email_id'), nullable=False)
    chat_dump = db.Column(db.JSON, nullable=False)
    date = db.Column(db.Date, nullable=False, default=datetime.date.today())

    # Relationships
    user = db.relationship('User', backref=db.backref('chat_histories', lazy=True))

    def __repr__(self):
        return f'<UserChatHistory {self.email_id}>'
@app.route('/save_user_chat_history', methods=['POST'])
def save_user_chat_history():
    data = request.json
    email_id = data.get('emailId')
    chat_dump = data.get('chatDump')
    try:
        chat_dump_json = json.loads(chat_dump)
        saved_date = list(chat_dump_json.keys())[0]
    except json.JSONDecodeError:
        return jsonify({'error': 'Invalid chatDump format. Expected JSON.'}), 400
    

    # Find user by email
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'error': 'User not found.'}), 404

    # Create a new UserChatHistory instance
    new_chat_history = UserChatHistory(
        email_id=email_id,
        chat_dump=chat_dump_json,
    )

    # Add to the session and commit
    try:
        db.session.add(new_chat_history)
        db.session.commit()
        return jsonify({'message': 'Chat history saved successfully.'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/get_user_chat_history', methods=['GET'])
def get_user_chat_history():
    email_id = request.args.get('emailId')
    if not email_id:
        return jsonify({'error': 'Missing emailId parameter'}), 400

    # Find user by email
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Fetch UserChatHistory for the user
    chat_histories = UserChatHistory.query.filter_by(email_id=email_id).all()

    if not chat_histories:
        return jsonify({'message': 'No chat history found for the given user.'}), 404

    # Serialize the chat histories
    chat_histories_dict = {}
    for chat_history in chat_histories:
        date_key = chat_history.date.strftime('%Y-%m-%d')
        chat_histories_dict[date_key] = chat_history.chat_dump
    print("chat_histories_dict", chat_histories_dict)
    return jsonify(chat_histories_dict), 200  
def determine_bmi_category(bmi):
    if bmi < 18.5:
        return 'Underweight'
    elif 18.5 <= bmi <= 24.9:
        return 'Normal Weight'
    elif 25.0 <= bmi <= 29.9:
        return 'Overweight'
    else:
        return 'Obese'

@app.route('/save_user_alternate_food', methods=['POST'])
def save_user_alternate_food():
    data = request.json
    email = data.get('email')
    food_item_name = data.get('foodItemName')

    # Find user by email
    user = User.query.filter_by(email_id=email).first()
    if not user:
        return jsonify({'error': 'User not found.'}), 404

    # Check if food item exists
    food_item = FoodItems.query.filter_by(FoodItemName=food_item_name).first()
    if not food_item:
        return jsonify({'error': 'Food item not found.'}), 404

    # Create a new UserAlternateFood instance
    new_alternate_food = UserAlternateFood(
        user_id=user.id,
        food_item_name=food_item_name,
        suggested_on=datetime.date.today(),
        suggested_time=datetime.datetime.now().time()
    )

    # Add to the session and commit
    try:
        db.session.add(new_alternate_food)
        db.session.commit()
        return jsonify({'message': 'Alternate food suggestion saved successfully.'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
    
@app.route('/get_user_alternate_food', methods=['GET'])
def get_user_alternate_food():
    email_id = request.args.get('emailId')
    if not email_id:
        return jsonify({'error': 'Missing email parameter'}), 400

    # Find user by email
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Fetch UserAlternateFood for the user
    alternate_foods = UserAlternateFood.query.filter_by(user_id=user.id).all()

    if not alternate_foods:
        return jsonify({'message': 'No alternate food suggestions found for the given user.'}), 404

    # Serialize the alternate foods similar to exercise suggestions
    alternate_foods_dict = {}
    for alternate_food in alternate_foods:
        food_item_name = alternate_food.food_item_name
        if food_item_name not in alternate_foods_dict:
            alternate_foods_dict[food_item_name] = {
                'suggested_on': alternate_food.suggested_on.strftime('%Y-%m-%d'),
                'suggested_time': alternate_food.suggested_time.strftime('%H:%M:%S'),
                'food_item': {
                    'name': food_item_name
                }
            }

    alternate_foods_list = list(alternate_foods_dict.values())

    return jsonify(alternate_foods_list), 200

@app.route('/save_user_exercise_suggestion', methods=['POST'])
def save_user_exercise_suggestion():
    data = request.json
    email_id = data.get('emailId')
    exercise_name = data.get('exerciseName')
    suggested_time = data.get('suggestedTime', None)  # Optional, defaults to None if not provided

    # Find user and exercise by their identifiers
    user = User.query.filter_by(email_id=email_id).first()
    exercise = Exercise.query.filter_by(workout_type=exercise_name).first()

    if not user or not exercise:
        return jsonify({'error': 'User or Exercise not found.'}), 404

    # Create a new UserExerciseSuggestions instance
    new_suggestion = UserExerciseSuggestions(
        user_id=user.id,
        exercise_id=exercise.id,
        # suggested_time=suggested_time
    )
    print("new_suggestion",new_suggestion)

    # Add to the session and commit
    try:
        db.session.add(new_suggestion)
        db.session.commit()
        return jsonify({'message': 'Exercise suggestion saved successfully.'}), 201
    except Exception as e:
        print("error",e)
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/get_user_exercise_suggestions', methods=['GET'])
def get_user_exercise_suggestions():
    email_id = request.args.get('emailId')
    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400

    # Find user by email_id
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Fetch UserExerciseSuggestions for the user, including related Exercise details
    suggestions = UserExerciseSuggestions.query.filter_by(user_id=user.id).join(Exercise, UserExerciseSuggestions.exercise_id == Exercise.id).all()

    if not suggestions:
        return jsonify({'message': 'No exercise suggestions found for the given user.'}), 404

    # Serialize the suggestions along with the Exercise details, removing duplicates
    suggestions_dict = {}
    for suggestion in suggestions:
        exercise_type = suggestion.exercise.workout_type
        if exercise_type not in suggestions_dict:
            suggestions_dict[exercise_type] = {
                'suggested_on': suggestion.suggested_on.strftime('%Y-%m-%d'),
                'suggested_time': suggestion.suggested_time,
                'exercise': {
                    'id': suggestion.exercise.id,
                    'workout_type': exercise_type
                }
            }

    suggestions_list = list(suggestions_dict.values())
    print("suggestions_list", suggestions_list)
    return jsonify(suggestions_list), 200

@app.route('/get_user_exercise_suggestions_by_date', methods=['GET'])
def get_user_exercise_suggestions_by_date():
    email_id = request.args.get('emailId')
    date_param = request.args.get('date')  # New date parameter

    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400
    if not date_param:
        return jsonify({'error': 'Missing date parameter'}), 400

    try:
        date_obj = datetime.datetime.strptime(date_param, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD.'}), 400

    # Find user by email_id
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Fetch UserExerciseSuggestions for the user, including related Exercise details, filtered by date
    suggestions = UserExerciseSuggestions.query.filter_by(user_id=user.id, suggested_on=date_obj).join(Exercise, UserExerciseSuggestions.exercise_id == Exercise.id).all()

    if not suggestions:
        return jsonify({'message': 'No exercise suggestions found for the given user on the specified date.'}), 404

    # Serialize the suggestions along with the Exercise details, removing duplicates
    suggestions_dict = {}
    for suggestion in suggestions:
        exercise_type = suggestion.exercise.workout_type
        if exercise_type not in suggestions_dict:
            suggestions_dict[exercise_type] = {
                'suggested_on': suggestion.suggested_on.strftime('%Y-%m-%d'),
                'suggested_time': suggestion.suggested_time,
                'exercise': {
                    'id': suggestion.exercise.id,
                    'workout_type': exercise_type
                }
            }

    suggestions_list = list(suggestions_dict.values())
    return jsonify(suggestions_list), 200

#To calculate the suggested calories as per industry standards,
# you can use the Mifflin-St Jeor Equation for Basal Metabolic Rate (BMR)
# and then adjust it based on the activity level. 
# The Total Daily Energy Expenditure (TDEE) is calculated by multiplying the BMR with 
# an activity factor. Here's a separate method that takes age, gender, weight, height, and BMI 
# to calculate the suggested calories. 
def calculate_suggested_calories(age, gender, weight_kg, height_cm, bmi,
                                 activity_level, target_weight, 
                                 targetedDuration):
    """
    Calculate suggested daily calories intake for reaching the target weight within a specified duration.

    Parameters:
    - age: in years
    - gender: 'male' or 'female'
    - weight_kg: current weight in kilograms
    - height_cm: height in centimeters
    - bmi: Body Mass Index
    - activity_level: 'Sedentary', 'Lightly active', 'Moderately active', or 'Very active'
    - target_weight: desired weight in kilograms
    - targetedDuration: duration in weeks to reach the target weight

    Returns:
    - suggested_calories: Estimated daily calories intake to reach the target weight within the specified duration
    """
    # Calculate BMR for the current weight using the Mifflin-St Jeor Equation
    if gender == 'Male':
        bmr_current = (10 * float(weight_kg)) + (6.25 * float(height_cm)) - (5 * age) + 5
    else:  # female
        bmr_current = (10 * float(weight_kg)) + (6.25 * float(height_cm)) - (5 * age) - 161

    # Calculate BMR for the target weight using the same equation
    if gender == 'Male':
        bmr_target = (10 * float(target_weight)) + (6.25 * float(height_cm)) - (5 * age) + 5
    else:
        bmr_target = (10 * float(target_weight)) + (6.25 * float(height_cm)) - (5 * age) - 161

    # Map activity level to a multiplier
    
    activity_multipliers = {
        'Sedentary': 1.2,
        'Lightly active': 1.375,
        'Moderately active': 1.55,
        'Very active': 1.725
    }

    activity_factor = activity_multipliers.get(activity_level, 1.2)  # Default to Sedentary if not found

    # Calculate Total Daily Energy Expenditure (TDEE) for both current and target BMRs
    tdee_current = bmr_current * activity_factor
    tdee_target = bmr_target * activity_factor

    # Calculate the calorie deficit or surplus per day required to reach the target weight within the targeted duration
    weight_difference_kg = float(weight_kg) - float(target_weight)
    calories_per_kg = 7700  # Approximate calories per kg of body weight
    total_calories_difference = abs(weight_difference_kg) * calories_per_kg
    daily_calories_difference = total_calories_difference / (int(targetedDuration) * 7)  # Convert weeks to days

    # Adjust the suggested calories intake based on the target weight and duration
    if float(target_weight) < float(weight_kg):
        suggested_calories = tdee_current - daily_calories_difference  # Creating a deficit to lose weight
    elif float(target_weight) > float(weight_kg):
        suggested_calories = tdee_current + daily_calories_difference  # Creating a surplus to gain weight
    else:
        suggested_calories = tdee_current  # Maintain current weight

    return suggested_calories
@app.route('/update_user_profile', methods=['POST'])
def update_user_profile():
    data = request.json  # Get the JSON data sent to the endpoint
    
    # Extract user identification and profile update data
    
    email_id = data.get('emailId')
    if not email_id:
        return jsonify({'error': 'Missing emailId parameter'}), 400
    
    # Find user by email
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'error': 'User not found.'}), 404
    
    # Update user profile fields if provided in the request
    if 'fullName' in data:
        user.full_name = data['fullName']
    if 'height' in data:
        user.height = float(data['height'])
    if 'weight' in data:
        user.weight = float(data['weight'])
    if 'dateOfBirth' in data:
        user.date_of_birth = data['dateOfBirth']
        print("data['dateOfBirth']",data['dateOfBirth'])
        age = (datetime.datetime.today().date() - datetime.datetime.strptime(data['dateOfBirth'], '%Y-%m-%d').date()).days // 365
    if 'gender' in data:
        user.gender = data['gender']
    if 'activityLevel' in data:
        user.activity_level = data['activityLevel']
    if 'duration' in data:
        user.duration = data['duration']
    if 'targetWeight' in data:
        user.target_weight = data['targetWeight']
    if 'suggestedCalories' in data:
        suggested_calories = calculate_suggested_calories(age=age, gender=user.gender, weight_kg=data['weight'], height_cm=float(float(data['height'])), bmi=user.bmi, activity_level=data['activityLevel'], target_weight=data['targetWeight'], targetedDuration=data['duration'])        
        print("suggested_calories",suggested_calories)
        user.suggested_calories = suggested_calories
    if 'bmi' in data:
        height_in_meters = float(data['height']) / 100
        user.bmi =float(data['weight']) / ((height_in_meters) ** 2)
    if 'bmiCategory' in data:
        user.bmi_category = determine_bmi_category(user.bmi)
        
    # Save the changes to the database
    
    try:
        db.session.commit()
        return jsonify({'message': 'User profile updated successfully.'}), 200
    except Exception as e:
        print("Exception",e)
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
@app.route('/register', methods=['POST'])
def register_user():
    # insert_food_items()
    # Access form data (text fields)
    data = request.form.to_dict()
    height_in_meters = int(data['height'])
    bmi = float(data['weight']) / ((float(data['height'])*100) ** 2)
    bmi_category = determine_bmi_category(bmi)  # Determine the BMI category
    activity_level = data['activityLevel']
    date_of_birth = datetime.datetime.strptime(data['dateOfBirth'], '%Y-%m-%d').date()
    today = datetime.datetime.today().date()
    age = today.year - date_of_birth.year - ((today.month, today.day) < (date_of_birth.month, date_of_birth.day))
    target_weight = float(data['targetWeight'])
    duration = int(data['duration'])
    gender = data['gender']
    
    

    # Handle profile picture upload
    profile_pic_file = request.files.get('profilePic')
    filename = "None"
    if profile_pic_file:
        filename = secure_filename(profile_pic_file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        profile_pic_file.save(file_path)
        # Optionally, process the file (e.g., resize) or store in a different location

    try:
        if profile_pic_file:
            profile_pic_path = file_path
        else:
            profile_pic_path = None
        suggested_calories = calculate_suggested_calories(age=age, gender=data['gender'], weight_kg=data['weight'], height_cm=data['height'], bmi=bmi, activity_level=data['activityLevel'], target_weight=target_weight, targetedDuration=duration)
        print("suggested_calories",suggested_calories)
        new_user = User(email_id=data['email'], full_name=data['fullName'],
                        height=data['height'], weight=data['weight'], date_of_birth=data['dateOfBirth'],
                        profile_pic=profile_pic_path, bmi=bmi, bmi_category=bmi_category,
                        suggested_calories=suggested_calories,activity_level=activity_level,
                        target_weight=target_weight,duration=duration,gender=gender)
        new_user.set_password(data['password'])  # Set the hashed password
        db.session.add(new_user)
        db.session.commit()
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
        print("predicted_calories",predicted_calories)
        user = User.query.filter_by(email_id=user_email).first()
        print("user",user,"user.id",user.id)
        food_item = FoodItems.query.filter_by(FoodItemName=food_item_name).first()
        print("food_item",food_item,"food_item.id",food_item.id)
        meal_type = MealType.query.filter_by(name=meal_type_name).first()
        print("meal_type",meal_type)
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
        print("new_meals",new_meals)
        db.session.add_all(new_meals)
        db.session.commit()
        return jsonify({'message': f'{len(new_meals)} meals added successfully.'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Failed to add meals.', 'error': str(e)}), 500

@app.route('/user_meals_by_email', methods=['GET'])
def user_meals_by_email():
    from datetime import date

    email_id = request.args.get('email_id')
    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400

    # Find user by email_id
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Query to fetch user meals for today and join with MealType to categorize them
    today_date = date.today()
    user_meals = db.session.query(
        UserMeals, MealType.name.label('meal_type_name')
    ).join(MealType, UserMeals.meal_type_id == MealType.id
    ).filter(UserMeals.user_id == user.id, UserMeals.date == today_date).all()

    if not user_meals:
        return jsonify({'message': 'No meals found for the given user email for today.'}), 404

    # Group meals by meal type
    meals_by_type = defaultdict(list)
    for meal, meal_type_name in user_meals:
        meals_by_type[meal_type_name].append(meal)

    # Serialize the results
    output = {}
    for meal_type, meals in meals_by_type.items():
        output[meal_type] = [[meal.food_item.FoodItemName, round(meal.calories,2), meal.volume, meal.weight, meal_type] for meal in meals]

    return jsonify(output), 200

@app.route('/user_meals_by_email_and_type', methods=['GET'])
def user_meals_by_email_and_type():
    from datetime import date

    email_id = request.args.get('email_id')
    meal_type_name_param = request.args.get('meal_type')

    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400
    if not meal_type_name_param:
        return jsonify({'error': 'Missing meal_type parameter'}), 400

    # Find user by email_id
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Query to fetch user meals for today and join with MealType to categorize them
    today_date = date.today()
    user_meals = db.session.query(
        UserMeals, MealType.name.label('meal_type_name')
    ).join(MealType, UserMeals.meal_type_id == MealType.id
    ).filter(UserMeals.user_id == user.id, UserMeals.date == today_date, MealType.name == meal_type_name_param).all()

    if not user_meals:
        return jsonify({'message': f'No {meal_type_name_param} meals found for the given user email for today.'}), 404

    # Group meals by meal type
    meals_by_type = defaultdict(list)
    for meal, meal_type_name in user_meals:
        meals_by_type[meal_type_name].append(meal)

    # Serialize the results
    output = {}
    dupl_list = []
    for meal_type, meals in meals_by_type.items():        
        output[meal_type] = [[meal.food_item.FoodItemName, round(meal.calories,2), meal.volume, meal.weight, meal_type] for meal in meals]
    for key, value in output.items():
        for val in value:
            if val[0] not in dupl_list:
                dupl_list.append(val[0])
            else:
                index = dupl_list.index(val[0])
                output[key][index][1] = output[key][index][1] + val[1]
    # Remove duplicates from output values
    for meal_type, meals in output.items():
        unique_meals = []
        seen = set()
        for meal in meals:
            if meal[0] not in seen:
                seen.add(meal[0])
                unique_meals.append(meal)
        output[meal_type] = unique_meals
    return jsonify(output), 200


@app.route('/total_calories_by_email_and_type', methods=['GET'])
def total_calories_by_email_and_type():
    from datetime import date

    email_id = request.args.get('email_id')
    meal_type_name_param = request.args.get('meal_type')

    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400
    if not meal_type_name_param:
        return jsonify({'error': 'Missing meal_type parameter'}), 400

    # Find user by email_id
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Query to fetch user meals for today and join with MealType to categorize them
    today_date = date.today()
    user_meals = db.session.query(
        UserMeals.calories
    ).join(MealType, UserMeals.meal_type_id == MealType.id
    ).filter(UserMeals.user_id == user.id, UserMeals.date == today_date, MealType.name == meal_type_name_param).all()

    if not user_meals:
        return jsonify({'message': f'No {meal_type_name_param} meals found for the given user email for today.'}), 404

    # Calculate the total calories for the given meal type
    total_calories = sum(meal.calories for meal in user_meals if meal.calories is not None)
    print(total_calories,meal_type_name_param)
    return jsonify({'email_id': email_id, 'meal_type': meal_type_name_param, 'total_calories': round(total_calories, 0)}), 200

@app.route('/user_meals_summary_by_email', methods=['GET'])
def user_meals_summary_by_email():
    from datetime import date

    email_id = request.args.get('email_id')
    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400

    # Find user by email_id
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Query to fetch user meals for today and join with MealType to categorize them
    today_date = date.today()
    user_meals = db.session.query(
        UserMeals, MealType.name.label('meal_type_name')
    ).join(MealType, UserMeals.meal_type_id == MealType.id
    ).filter(UserMeals.user_id == user.id, UserMeals.date == today_date).all()

    if not user_meals:
        return jsonify({'message': 'No meals found for the given user email for today.'}), 404

    # Summarize calories by meal type for today
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
    return jsonify({'calories': round(prediction[0],2)})

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
    return jsonify({'calories': round(predictions[0],2)})

@app.route('/suggestExercise', methods=['POST'])
def predict_exercises():
    # Extract 'calories' from the request
    model = joblib.load('calories_based_workout_predictor.pkl')

    data = request.get_json()
    calories = data.get('dailyCalorieLimit')
    
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
    print("top_3_workouts",top_3_workouts)
    
    return jsonify({'top_3_suggestions': top_3_workouts})


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
    calories = data.get('dailyCalorieLimit')
    
    if calories is None:
        return jsonify({'error': 'Missing parameter: calories'}), 400
    
    # Assuming the classifier expects a DataFrame with a 'calories' column
    # and you have preprocessed your data accordingly during model training
    input_df = pd.DataFrame({'calories': [calories], 'time': [0]})  # Dummy 'time' value, not used by the classifier
    
    # Predict the top 3 workout types
    classifier = joblib.load('exercise_classifier.pkl')
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

@app.route('/total_calories_by_email_and_date', methods=['GET'])
def total_calories_by_email_and_date():
    email_id = request.args.get('email_id')
    date_param = request.args.get('date')

    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400
    if not date_param:
        return jsonify({'error': 'Missing date parameter'}), 400

    try:
        date_obj = datetime.datetime.strptime(date_param, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD.'}), 400

    # Find user by email_id
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Query to fetch user meals for the specified date and calculate total calories per meal type
    user_meals = db.session.query(
        MealType.name.label('meal_type_name'),
        db.func.sum(UserMeals.calories).label('total_calories')
    ).join(MealType, UserMeals.meal_type_id == MealType.id
    ).filter(UserMeals.user_id == user.id, UserMeals.date == date_obj
    ).group_by(MealType.name).all()

    if not user_meals:
        return jsonify({'message': f'No meals found for the given user email on {date_param}.'}), 404

    # Serialize the results
    meals_output = {meal_type_name: round(total_calories, 2) for meal_type_name, total_calories in user_meals}
    print("meals_output",meals_output)

    return jsonify({
        "Breakfast": meals_output["Breakfast"] if "Breakfast" in meals_output else 0,
        "Lunch": meals_output["Lunch"] if "Lunch" in meals_output else 0,
        "Dinner": meals_output["Dinner"] if "Dinner" in meals_output else 0,
        "Others": meals_output["Others"] if "Others" in meals_output else 0
    }), 200

@app.route('/total_calories_by_email_per_day', methods=['GET'])
def total_calories_by_email_and_date_simple():
    email_id = request.args.get('email_id')
    date_param = request.args.get('date')

    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400
    if not date_param:
        return jsonify({'error': 'Missing date parameter'}), 400

    try:
        date_obj = datetime.datetime.strptime(date_param, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD.'}), 400

    # Find user by email_id
    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    # Query to fetch user meals for the specified date and calculate total calories
    total_calories = db.session.query(
        db.func.sum(UserMeals.calories)
    ).filter(UserMeals.user_id == user.id, UserMeals.date == date_obj).scalar()

    if total_calories is None:
        return jsonify({'message': f'No meals found for the given user email on {date_param}.'}), 404

    # Return the total calories
    return jsonify({'total_calories': round(total_calories, 2)}), 200


@app.route('/predictFromImage', methods=['POST'])
def predictFromImage():
    email_id = request.args.get('userEmail')
    meal_type = request.args.get('mealType')
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
        caloires_predicted[nutritional_info_resp_jasn['foodName'][0]] = round(nutritional_info_resp_jasn["nutritional_info"]["calories"],2)
        save_to_db(caloires_predicted,email_id,meal_type)
        os.remove(file_path)
        return jsonify(caloires_predicted)
    
def save_to_db(caloires_predicted,email_id,meal_type):
    category = "ImageUpload"
    meal_type = meal_type
    email = email_id
    date = datetime.datetime.now().strftime('%Y-%m-%d')
    time = datetime.datetime.now().strftime('%H:%M:%S')
    weight = "0"
    volume = 0
    calories = str(caloires_predicted)
    caffeine = 0
    cals_per_100grams = "0"
    kj_per_100grams = "0"
    user = User.query.filter_by(email_id=email).first()
    meal_type_id = MealType.query.filter_by(name=meal_type).first().id
    existing_category = FoodCategory.query.filter_by(name=category).first()
    for food_item, calories in caloires_predicted.items():
        food_item = food_item[0].upper() + food_item[1:]
        existing_entry = FoodItems.query.filter_by(FoodItemName=food_item).first()
        if not existing_entry:
            existing_entry = FoodItems(
                    FoodItemName=food_item,
                    volume_ml=float(volume),
                    Calories=calories,
                    caffeine_mg=float(caffeine),
                    Cals_per100grams=cals_per_100grams,  # Default value, adjust if needed
                    KJ_per100grams=kj_per_100grams,  # Default value, adjust if needed
                    category_id=existing_category.id
                )
            db.session.add(existing_entry)
            print("exisint added")
        new_meal = UserMeals(user_id=user.id, item_id=existing_entry.id, meal_type_id=meal_type_id, date=date, time=time,
                             weight = float(weight),volume = float(volume),calories=float(calories),caffeine=float(caffeine))
        db.session.add(new_meal)
        print("new meal added")
    db.session.commit()

@app.route('/get_alternate_food', methods=['GET'])
def get_alternate_food():
    try:
        target_calories = float(request.args.get('dailyCalorieLimit'))
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
        return jsonify({"alternate_food_suggestions": [{item.FoodItemName: str(round(float(item.Cals_per100grams.replace('cal', '')),2))} for item in top_3_alternates]}), 200
    else:
        return jsonify({'message': 'No alternate food items found close to the target calories'}), 404

@app.route('/user_profile', methods=['GET'])
def get_user_profile():
    email_id = request.args.get('email_id')
    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400

    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    user_profile = {
        'email_id': user.email_id,
        'full_name': user.full_name,
        'height': user.height,
        'weight': user.weight,
        'date_of_birth': user.date_of_birth.strftime('%Y-%m-%d'),
        'profile_pic': user.profile_pic,
        'bmi': round(user.bmi,2),
        'bmi_category': user.bmi_category,
        'suggested_calories': round(user.suggested_calories,2),
        'activity_level': user.activity_level,
        'target_weight': user.target_weight,
        'duration': int(user.duration),
    }

    return jsonify(user_profile), 200   

@app.route('/get_suggested_calories', methods=['GET'])
def get_suggested_calories():
    email_id = request.args.get('email_id')
    if not email_id:
        return jsonify({'error': 'Missing email_id parameter'}), 400

    user = User.query.filter_by(email_id=email_id).first()
    if not user:
        return jsonify({'message': 'User not found.'}), 404

    return jsonify({'email_id': user.email_id, 'suggested_calories': user.suggested_calories}), 200




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
    print("inserting unique categories")
    # insert_unique_categories()
    print("testing")
    # Ensure categories are inserted first
    # insert_unique_categories()
    
    # Insert items from caffeine.csv
    print("inserting caffeine")
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
    print("inserting calories")
    with open('archive-4/calories.csv', mode='r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            category = FoodCategory.query.filter_by(name=row['FoodCategory']).first()
            Cals_per100grams=row['Cals_per100grams'] if row['Cals_per100grams'] else "0",
            
            if 'cal' in Cals_per100grams:
                Cals_per100grams = Cals_per100grams.replace('cal', '')[0]
            # print("Cals_per100grams",Cals_per100grams)    
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
    print("inserting menu")
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
                    
                unique_workouts = set()
        print("inserting activity")
        with open('archive-4/Activity_Dataset_V1.csv', mode='r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                workout_type = row['workout_type']
                if workout_type not in unique_workouts:
                    unique_workouts.add(workout_type)
                    new_exercise = Exercise(workout_type=workout_type)
                    db.session.add(new_exercise)      
    print()  
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
        # insert_food_items()
        db.create_all()  
        print("db created")      
    app.run(debug=True)

