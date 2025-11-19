from flask import Flask, render_template, request, redirect, url_for, flash, session
import pymysql
from utils import *
import logging
import math
import datetime
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import logger
import traceback

app = Flask(__name__)

# Set the secret key to a unique and random string
app.secret_key = 'your_unique_secret_key'

# Alternatively, you can use a random generator for added security
# import os
# app.secret_key = os.urandom(24)

def get_db_connection():
    return pymysql.connect(
        host='localhost',
        user='root',
        password='',
        db='FSL',
        cursorclass=pymysql.cursors.DictCursor  # Returns rows as dictionaries
    )

# Main route to test the app
@app.route('/')
def home():
    return render_template('base.html')  # Ensure you have a home.html template

# Dashboard route
@app.route('/dashboard')
def dashboard():
    if 'user_name' not in session or session['user_name'] is None:
        return redirect(url_for('login'))  # Redirect to login if the user isn't logged in
    
    username = session['user_name']

    # No need to query the database; directly render the dashboard template
    return render_template('dashboard.html', username=username)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # get the form data
        username = request.form.get('input_user')
        password = request.form.get('input_password')

        # check if the username and password are provided
        if not username or not password:
            flash("Username and password are required.", "danger")
            return redirect(url_for('login'))

        connection = get_db_connection()
        cursor = connection.cursor()

        try:
            # check if the username or email exists in the database
            cursor.execute("""
                SELECT UserID, UserName, Pwd FROM User WHERE Email = %s OR UserName = %s
            """, (username, username))
            user = cursor.fetchone()
        except Exception as e:
            logging.error(f"Error during login: {e}")
            flash("An error occurred. Please try again.", "danger")
            return redirect(url_for('login'))
        finally:
            connection.close()

        if user and check_password_hash(user['Pwd'], password):
            # if found, log in the user
            session['user_id'] = user['UserID']
            session['user_name'] = user['UserName']
            flash("Logged in successfully!", "success")
            return redirect(url_for('dashboard'))  # redirect to the dashboard
        else:
            # if not found, show an error message
            flash("Invalid username/email or password.", "danger")
            return redirect(url_for('login'))

    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        # register the user
        full_name = request.form.get('full_name')
        email = request.form.get('email')
        username = request.form.get('user_name')
        password = request.form.get('password')
        position = request.form.get('position')  # 'U' for User or 'A' for Admin

        # check if all fields are provided
        if not full_name or not email or not username or not password or not position:
            flash("All fields are required.", "danger")
            return redirect(url_for('register'))

        # generate a hashed password
        hashed_password = generate_password_hash(password, method='pbkdf2:sha256', salt_length=16)

        connection = get_db_connection()
        cursor = connection.cursor()

        try:
            # check if the email or username already exists
            cursor.execute("""
                SELECT UserID FROM User WHERE Email = %s OR UserName = %s
            """, (email, username))
            existing_user = cursor.fetchone()
            if existing_user:
                flash("Email or Username already exists.", "danger")
                return redirect(url_for('register'))

            # insert the new user into the database
            cursor.execute("""
                INSERT INTO User (FullName, Email, UserName, Pwd, Position, ProfileSetting)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (full_name, email, username, hashed_password, position, 'Public'))
            connection.commit()
            flash("Registration successful! You can now log in.", "success")
            return redirect(url_for('login'))
        except Exception as e:
            connection.rollback()
            flash("An error occurred during registration. Please try again.", "danger")
            logging.error(f"Error during registration: {e}")
            return redirect(url_for('register'))
        finally:
            connection.close()
    else:
        return render_template('register.html')
    

# Flask route for LogoutUser
@app.route('/logout')
def logout():
    # Clear the session data
    session.clear()
    # Optionally, you can also flash a message
    flash("You have been logged out successfully.", "success")
    # Redirect the user to the login page
    return redirect(url_for('login'))

# Flask route for Leagues
@app.route('/leagues')
def leagues():
    return render_template('leagues.html')

# Flask route for GetUserPublicLeaguesAndTeamRankings
@app.route('/get_user_public_leagues')
def get_user_public_leagues():
    # Ensure the user is logged in
    if 'user_id' not in session or session['user_id'] is None:
        return redirect(url_for('login'))

    user_id = session['user_id']
    leagues = []

    # Establish a database connection
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            # Call the stored procedure with the user_id from the session
            cursor.callproc('GetUserPublicLeaguesAndTeamRankings', (user_id,))
            result = cursor.fetchall()
            
            if result:
                leagues = result  # Populate the leagues list if results found
            else:
                leagues = []  # No leagues found for this user
    finally:
        connection.close()

    # Render the template without needing to pass user_id or form_submitted
    return render_template('public_leagues.html', leagues=leagues)

# Flask route for GetUserPrivateLeaguesAndTeamRankings
@app.route('/get_user_private_leagues')
def get_user_private_leagues():
    # Ensure the user is logged in
    if 'user_id' not in session or session['user_id'] is None:
        return redirect(url_for('login'))

    user_id = session['user_id']
    leagues = []

    # Establish a database connection
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            # Call the stored procedure with the user_id from the session
            cursor.callproc('GetUserPrivateLeaguesAndTeamRankings', (user_id,))
            result = cursor.fetchall()
            
            if result:
                leagues = result  # Populate the leagues list if results found
            else:
                leagues = []  # No leagues found for this user
    finally:
        connection.close()

    # Render the template with the leagues data
    return render_template('private_leagues.html', leagues=leagues)

# Flask route for Teams
@app.route('/teams')
def teams():
    return render_template('teams.html')

# Flask route for GetUserTeams
@app.route('/get_user_teams')
def get_user_teams():
    # Check if the user is logged in
    if 'user_id' not in session or session['user_id'] is None:
        return redirect(url_for('login'))
    
    user_id = session.get('user_id')
    teams = []

    # Establish a database connection
    connection = get_db_connection()
    
    try:
        with connection.cursor() as cursor:
            # Call the stored procedure with the user_id from the session
            cursor.callproc('GetUserTeams', (user_id,))
            result = cursor.fetchall()
            if result:
                teams = result
            else:
                teams = []
    finally:
        connection.close()

    # Render the template with the teams data
    return render_template('user_teams.html', teams=teams)

# Flask route for GetTeamInfoByName
@app.route('/get_team_info_by_name', methods=['GET', 'POST'])
def get_team_info_by_name():
    team_name = request.args.get('team_name')

    connection = get_db_connection()
    
    try:
        with connection.cursor() as cursor:
            cursor.callproc('GetTeamInfoByName', (team_name,))
            result = cursor.fetchall()
            if result:
                return render_template('team_info.html', team_info=result, team_name=team_name)
            else:
                return render_template('team_info.html', team_info=[], team_name=team_name)
    finally:
        connection.close()

# Flask route for CreateTeam
@app.route('/create_team', methods=['GET', 'POST'])
def create_team():
    # Check if user is logged in
    if 'user_id' not in session:
        flash("Please log in to create a new team.", "danger")
        return redirect(url_for('login'))

    try:
        if request.method == 'POST':
            # Get form data
            team_name = request.form.get('team_name')
            sport_type = request.form.get('sport_type')
            league_id = request.form.get('league_id')

            # Validate form data
            if not team_name or not league_id or not sport_type:
                flash("All fields are required.", "danger")
                return redirect(url_for('create_team'))

            # Convert IDs to integers
            league_id = int(league_id)
            user_id = int(session['user_id'])

            # Establish database connection
            connection = get_db_connection()
            cursor = connection.cursor()

            # Fetch league details
            cursor.execute("""
                SELECT LeagueID, MaxNumber FROM League
                WHERE LeagueID = %s AND Sport = %s
            """, (league_id, sport_type))
            league = cursor.fetchone()

            if not league:
                flash("League not found with the given ID and sport type.", "danger")
                return redirect(url_for('create_team'))

            # Check if team name is already taken
            cursor.execute("""
                SELECT * FROM Team
                WHERE TeamName = %s AND LeagueID = %s
            """, (team_name, league_id))
            existing_team = cursor.fetchone()

            if existing_team:
                flash("Team name already exists in this league. Please choose a different name.", "danger")
                return redirect(url_for('create_team'))

            # Begin transaction by setting autocommit to False
            connection.autocommit = False

            try:
                # Get the next TeamID with row-level locking
                cursor.execute("SELECT MAX(TeamID) AS max_id FROM Team FOR UPDATE")
                result = cursor.fetchone()
                max_id = result['max_id']
                next_team_id = max_id + 1 if max_id else 1

                # Log the values before insertion
                app.logger.debug(f"Inserting Team: TeamID={next_team_id}, TeamName='{team_name}', Manager={user_id}, LeagueID={league_id}, Sport='{sport_type}'")

                # Insert new team
                cursor.execute("""
                    INSERT INTO Team (TeamID, TeamName, Manager, LeagueID, TotalPoints, LeagueRanking, TeamStatus, Sport)
                    VALUES (%s, %s, %s, %s, 0.00, NULL, 'A', %s)
                """, (next_team_id, team_name, user_id, league_id, sport_type))

                # Commit transaction
                connection.commit()
            # except pymysql.connector.Error as err:
            #     # Roll back the transaction on error
            #     connection.rollback()
            #     error_message = f"Database error occurred: {err.msg}"
            #     flash(error_message, "danger")
            #     app.logger.error(f"Database Error in create_team: {err}")
            #     app.logger.error("Traceback: " + traceback.format_exc())
                return render_template('create_team.html', leagues=[], sport_types=[])
            except Exception as e:
                # Roll back the transaction on error
                connection.rollback()
                error_message = f"An unexpected error occurred: {e}"
                flash(error_message, "danger")
                app.logger.error(f"Error in create_team: {e}")
                app.logger.error("Traceback: " + traceback.format_exc())
                return render_template('create_team.html', leagues=[], sport_types=[])
            finally:
                # Set autocommit back to True
                connection.autocommit = True

            flash("Team created successfully!", "success")
            return redirect(url_for('dashboard'))

        else:
            # GET request
            connection = get_db_connection()
            cursor = connection.cursor()

            # Fetch all leagues
            cursor.execute("SELECT LeagueID, LeagueName, Sport FROM League")
            leagues = cursor.fetchall()

            if not leagues:
                flash("No leagues available. Please create a league first.", "danger")
                return redirect(url_for('dashboard'))

            # Accessing 'Sport' using the key
            sport_types = list(set(league['Sport'] for league in leagues))

            return render_template('create_team.html', leagues=leagues, sport_types=sport_types)
    except Exception as e:
        if 'connection' in locals():
            connection.rollback()
            connection.autocommit = True
        error_message = f"An unexpected error occurred: {e}"
        flash(error_message, "danger")
        app.logger.error(f"Error in create_team: {e}")
        app.logger.error("Traceback: " + traceback.format_exc())
        return render_template('create_team.html', leagues=[], sport_types=[])
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'connection' in locals():
            connection.close()


# lzd
@app.route('/matches', methods=['GET'])
def matches():
    """
    Display all matches with options to sort by Date or Team and filter by Sport.
    """
    # Get query parameters
    sport = request.args.get('sport', 'FTB')  # Default sport
    order_by = request.args.get('order_by', 'Date')  # Default sorting

    # Validate query parameters
    valid_sports = ['FTB', 'BB', 'SB']
    valid_order_fields = ['Date', 'Team']

    if sport not in valid_sports:
        flash("Invalid sport selected. Please choose 'FTB', 'BB', or 'SB'.", 'danger')
        sport = 'FTB'  # Reset to default

    if order_by not in valid_order_fields:
        flash("Invalid sorting option. Please choose 'Date' or 'Team'.", 'danger')
        order_by = 'Date'  # Reset to default

    # Establish a database connection
    connection = get_db_connection()

    try:
        # Fetch matches using the stored procedure
        matches_data = GetMatches(connection, sport, order_by)

        # Check for error messages returned from the utility function
        if isinstance(matches_data, dict) and 'ErrorMessage' in matches_data:
            flash(matches_data['ErrorMessage'], 'danger')
            matches_data = []

        # Render the template with the fetched matches
        return render_template('matches.html', matches=matches_data, sport=sport, order_by=order_by)

    except Exception as e:
        # Log unexpected errors and inform the user
        logging.error(f"Unexpected error in matches: {e}")
        flash("An unexpected error occurred. Please try again later.", 'danger')
        return render_template('matches.html', matches=[], sport=sport, order_by=order_by)

    finally:
        # Close the database connection
        connection.close()

# Route to view match events
@app.route('/match_events/<int:match_id>', methods=['GET'])
def match_events(match_id):
    """
    Display all events for a specific match with options to sort by Player ID or Event Time.
    """
    # get the 'order_by' query parameter, default to 'Time'
    order_by = request.args.get('order_by', 'Time')

    # validate the 'order_by' parameter
    valid_order_fields = ['Player', 'Time']

    if order_by not in valid_order_fields:
        flash("Invalid sorting option. Please choose 'Player' or 'Time'.", 'danger')
        order_by = 'Time'  # reset to default

    connection = get_db_connection()

    try:
        # get match events using the utility function
        events = GetMatchEvents(connection, match_id, order_by)

        if not events:
            flash("No events found for this match.", 'info')

        return render_template('match_events.html', events=events, match_id=match_id, order_by=order_by)

    except Exception as e:
        logging.error(f"Unexpected error in match_events: {e}")
        flash("An unexpected error occurred. Please try again later.", 'danger')
        return render_template('match_events.html', events=[], match_id=match_id, order_by=order_by)

    finally:
        connection.close()



@app.route('/players', methods=['GET'])
def get_all_player_stats():
    """
    Displays player stats with sorting options for 'Name', 'Fantasy Points', or 'Sport' and pagination.
    Includes admin check and passes 'is_admin' to the template.
    """
    # Get the 'order_by' query parameter, default to 'Name'
    order_by = request.args.get('order_by', 'Name')

    # Get the 'page' query parameter, default to 1
    try:
        page = int(request.args.get('page', 1))
        if page < 1:
            page = 1
    except ValueError:
        page = 1

    # Define how many players to show per page
    players_per_page = 20

    # Validate the 'order_by' parameter
    valid_order_by = ['Name', 'Fantasy Points', 'Sport']
    if order_by not in valid_order_by:
        flash("Invalid sorting option. Please use 'Name', 'Fantasy Points', or 'Sport'.", 'danger')
        order_by = 'Name'

    # Establish a database connection
    connection = get_db_connection()

    try:
        # Check if the user is logged in and determine if they are an admin
        is_admin = False
        if 'user_id' in session:
            cursor = connection.cursor()
            cursor.execute("SELECT Position FROM User WHERE UserID = %s", (session['user_id'],))
            user = cursor.fetchone()
            if user and user['Position'] == 'A':
                is_admin = True

        # Fetch player stats using the utility function
        players = GetAllPlayerStats(connection, order_by)
        # print(players)
        # Calculate total pages
        total_players = len(players)
        total_pages = math.ceil(total_players / players_per_page) if total_players > 0 else 1

        # Ensure the current page is within bounds
        if page > total_pages and total_pages != 0:
            page = total_pages

        # Calculate start and end indices for slicing
        start_idx = (page - 1) * players_per_page
        end_idx = start_idx + players_per_page
        players_paginated = players[start_idx:end_idx]

        # Generate pagination links
        pagination = {
            'total_pages': total_pages,
            'current_page': page,
            'has_prev': page > 1,
            'has_next': page < total_pages,
            'prev_page': page - 1,
            'next_page': page + 1
        }

        # Render the template with the fetched player stats, pagination, and is_admin flag
        return render_template(
            'players.html',
            players=players_paginated,
            order_by=order_by,
            pagination=pagination,
            is_admin=is_admin  # Pass the is_admin variable to the template
        )

    except ValueError as ve:
        # Handle custom error messages
        flash(str(ve), 'danger')
        return redirect(url_for('get_all_player_stats'))
    except pymysql.MySQLError as e:
        # Log and inform the user of database errors
        logging.error(f"Error fetching player stats: {e}")
        flash("An error occurred while fetching player stats. Please try again later.", "danger")
        return redirect(url_for('get_all_player_stats'))
    finally:
        # Close the database connection
        connection.close()



@app.route('/player/<int:player_id>', methods=['GET', 'POST'])
def player_details(player_id):
    """
    Displays the details of a specific player.
    Allows admins to edit or delete player details.
    """
    # Check if the user is logged in
    if 'user_id' not in session:
        flash("Please log in to view player details.", "danger")
        return redirect(url_for('login'))

    # Establish a database connection
    connection = get_db_connection()

    try:
        # Get user position from the database
        cursor = connection.cursor()
        cursor.execute("SELECT Position FROM User WHERE UserID = %s", (session['user_id'],))
        user = cursor.fetchone()
        is_admin = user['Position'] == 'A'

        if request.method == 'POST':
            if is_admin:
                action = request.form.get('action')

                if action == 'update':
                    # Admin submitted changes to player details
                    # Retrieve form data
                    full_name = request.form.get('full_name')
                    position = request.form.get('position')
                    real_team = request.form.get('real_team')
                    fantasy_points = request.form.get('fantasy_points')
                    avai_status = request.form.get('avai_status')
                    photo_url = request.form.get('photo_url')

                    # Validate input
                    if not full_name or not position or not real_team:
                        flash("Please fill out all required fields.", "danger")
                    else:
                        try:
                            # Update player details in the database
                            cursor.execute("""
                                UPDATE Player
                                SET FullName = %s,
                                    Position = %s,
                                    RealTeam = %s,
                                    FantasyPoints = %s,
                                    AvaiStatus = %s,
                                    PhotoURL = %s
                                WHERE PlayerID = %s
                            """, (full_name, position, real_team, fantasy_points, avai_status, photo_url, player_id))
                            connection.commit()
                            flash("Player details updated successfully.", "success")
                        except Exception as e:
                            connection.rollback()
                            flash("An error occurred while updating player details.", "danger")
                            logging.error(f"Error updating player: {e}")

                elif action == 'delete':
                    # Admin wants to delete the player
                    try:
                        # Delete related records from PlayerStats
                        cursor.execute("DELETE FROM PlayerStats WHERE PlayerID = %s", (player_id,))
                        # Delete related records from MatchEvent
                        cursor.execute("DELETE FROM MatchEvent WHERE PlayerID = %s", (player_id,))
                        # Delete related records from PlayerTrade
                        cursor.execute("DELETE FROM PlayerTrade WHERE PlayerID = %s", (player_id,))
                        # Delete related records from Waiver
                        cursor.execute("DELETE FROM Waiver WHERE PlayerID = %s", (player_id,))

                        # Now delete the player
                        cursor.execute("DELETE FROM Player WHERE PlayerID = %s", (player_id,))
                        connection.commit()
                        flash("Player and all related data deleted successfully.", "success")
                        return redirect(url_for('get_all_player_stats'))
                    except Exception as e:
                        connection.rollback()
                        flash("An error occurred while deleting the player.", "danger")
                        logging.error(f"Error deleting player: {e}")
            else:
                flash("You do not have permission to perform this action.", "danger")

        # Use GetPlayerDetails to fetch player information
        player = GetPlayerDetails(connection, player_id)

        # Check if the player was found
        if not player:
            flash("Player not found.", "danger")
            return redirect(url_for('get_all_player_stats'))

        # Render the player details template
        return render_template('player_details.html', player=player, is_admin=is_admin)

    finally:
        # Ensure the connection is closed
        connection.close()

@app.route('/player/new', methods=['GET', 'POST'])
def create_player():
    """
    Allows admin users to create a new player.
    """
    # Check if the user is logged in
    if 'user_id' not in session:
        flash("Please log in to create a new player.", "danger")
        return redirect(url_for('login'))

    # Establish a database connection
    connection = get_db_connection()
    cursor = connection.cursor()

    try:
        # Get user position from the database
        cursor.execute("SELECT Position FROM User WHERE UserID = %s", (session['user_id'],))
        user = cursor.fetchone()
        is_admin = user['Position'] == 'A'

        if not is_admin:
            flash("You do not have permission to create a new player.", "danger")
            return redirect(url_for('get_all_player_stats'))

        if request.method == 'POST':
            # Get form data
            full_name = request.form.get('full_name')
            sport = request.form.get('sport')
            position = request.form.get('position')
            real_team = request.form.get('real_team')
            fantasy_points = request.form.get('fantasy_points')
            avai_status = request.form.get('avai_status')
            photo_url = request.form.get('photo_url')

            # Validate input (you can add more validation as needed)
            if not full_name or not sport or not position or not real_team:
                flash("Please fill out all required fields.", "danger")
            else:
                try:
                    # Insert new player into the database
                    cursor.execute("""
                        INSERT INTO Player (FullName, Sport, Position, RealTeam, FantasyPoints, AvaiStatus, PhotoURL)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (full_name, sport, position, real_team, fantasy_points, avai_status, photo_url))
                    connection.commit()
                    flash("New player created successfully.", "success")
                    return redirect(url_for('get_all_player_stats'))
                except Exception as e:
                    connection.rollback()
                    flash("An error occurred while creating the player.", "danger")
                    logging.error(f"Error creating player: {e}")
        else:
            # GET request, render the create player form
            return render_template('create_player.html')
    finally:
        # Ensure the connection is closed
        connection.close()




@app.route('/trade', methods=['GET'])
def trade():
    """
    Display trades with options to sort by Name, Sport, Fantasy Points, or Trade Date.
    """
    # Get query parameters
    order_by = request.args.get('order_by', 'Name')  # Default sorting by Name
    page = request.args.get('page', 1, type=int)     # Current page number

    # Validate sorting options
    valid_order_fields = ['Name', 'Sport', 'Fantasy Points', 'Trade Date']
    if order_by not in valid_order_fields:
        flash("Invalid sorting option. Please choose 'Name', 'Sport', 'Fantasy Points', or 'Trade Date'.", 'danger')
        order_by = 'Name'  # Reset to default

    # Define sorting SQL
    sort_mapping = {
        'Name': 'p.FullName ASC',
        'Sport': 't.Sport ASC',
        'Fantasy Points': 'p.FantasyPoints DESC',
        'Trade Date': 'tr.TradeDate DESC'  # Default sorting
    }
    sort_order = sort_mapping.get(order_by, 'p.FullName ASC')

    # Pagination settings
    trades_per_page = 10
    offset = (page - 1) * trades_per_page

    # Establish database connection
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:
            # Get total number of trades for pagination
            cursor.execute("""
                SELECT COUNT(*) AS count
                FROM PlayerTrade pt
                JOIN Player p ON pt.PlayerID = p.PlayerID
                JOIN Trade tr ON pt.TradeID = tr.TradeID
                JOIN Team t ON p.TeamID = t.TeamID
            """)
            total_trades = cursor.fetchone()['count']
            total_pages = math.ceil(total_trades / trades_per_page) if total_trades > 0 else 1

            # Fetch trades with sorting and pagination
            cursor.execute(f"""
                SELECT 
                    pt.PlayerID,
                    p.FullName,
                    p.PhotoURL,
                    p.RealTeam,
                    t.TeamName,
                    pt.FromOrTo,
                    tr.TradeDate
                FROM 
                    PlayerTrade pt
                JOIN 
                    Player p ON pt.PlayerID = p.PlayerID
                JOIN 
                    Trade tr ON pt.TradeID = tr.TradeID
                JOIN
                    Team t ON p.TeamID = t.TeamID
                ORDER BY 
                    {sort_order}
                LIMIT %s OFFSET %s
            """, (trades_per_page, offset))
            trades = cursor.fetchall()

        # Determine pagination flags
        has_prev = page > 1
        has_next = page < total_pages

        # Create pagination object
        pagination = {
            'current_page': page,
            'total_pages': total_pages,
            'has_prev': has_prev,
            'has_next': has_next,
            'prev_page': page - 1,
            'next_page': page + 1
        }

        return render_template('trade.html', trades=trades, order_by=order_by, pagination=pagination)

    except Exception as e:
        logging.error(f"Error fetching trades: {e}")
        flash("An error occurred while fetching trades. Please try again later.", "danger")
        return render_template('trade.html', trades=[], order_by=order_by, pagination={
            'current_page': 1,
            'total_pages': 1,
            'has_prev': False,
            'has_next': False,
            'prev_page': 1,
            'next_page': 1
        })
    finally:
        connection.close()

import logging
from datetime import datetime

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/start_trade', methods=['GET', 'POST'], endpoint='start_trade')
def start_trade():
    """
    Handle trade initiation and execution
    """
    if 'user_id' not in session:
        flash("Please log in to perform trades.", "danger")
        return redirect(url_for('login')) 

    user_id = session['user_id']

    try:
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                # 获取买方团队
                cursor.execute("SELECT TeamID, TeamName FROM Team WHERE Manager = %s", (user_id,))
                buyer_team = cursor.fetchone()
                # logger.info(f"Buyer team: {buyer_team}")

                if not buyer_team:
                    flash("You do not have a team to perform trades.", "danger")
                    return redirect(url_for('dashboard'))

                buyer_team_id = buyer_team['TeamID']

                # 获取卖方团队
                cursor.execute("SELECT TeamID, TeamName FROM Team WHERE TeamID != %s", (buyer_team_id,))
                seller_teams = cursor.fetchall()
                # logger.info(f"Seller teams: {seller_teams}")

                # 获取卖方玩家
                cursor.execute("""
                    SELECT p.PlayerID, p.FullName, p.RealTeam
                    FROM Player p
                    WHERE p.TeamID IN (
                        SELECT TeamID FROM Team WHERE TeamID != %s
                    ) AND p.AvaiStatus = 'A'
                """, (buyer_team_id,))
                seller_players = cursor.fetchall()
                # logger.info(f"Seller players: {seller_players}")

                # 获取买方玩家
                cursor.execute("""
                    SELECT p.PlayerID, p.FullName, p.RealTeam
                    FROM Player p
                    WHERE p.TeamID = %s AND p.AvaiStatus = 'A'
                """, (buyer_team_id,))
                your_players = cursor.fetchall()
                # logger.info(f"Your players: {your_players}")

                if request.method == 'POST':
                    # 获取表单数据
                    seller_team_id = request.form.get('seller_team_id')
                    seller_player_id = request.form.get('seller_player_id')
                    your_player_id = request.form.get('your_player_id')

                    # 数据验证
                    errors = []
                    if not seller_team_id:
                        errors.append("Seller team is required.")
                    if not seller_player_id:
                        errors.append("Seller player is required.")
                    if not your_player_id:
                        errors.append("Your player is required.")

                    if errors:
                        for error in errors:
                            flash(error, "danger")
                        return render_template('start_trade.html', 
                                               seller_teams=seller_teams, 
                                               seller_players=seller_players,
                                               your_players=your_players)

                    # 设置交易日期为当前日期
                    trade_date = datetime.today().date()

                    # 执行交易
                    result = ExecuteTrade(connection, user_id, seller_team_id, seller_player_id, your_player_id, trade_date)
                    # logger.info(f"Trade result: {result}")

                    if result['status'] == "Trade executed successfully.":
                        flash(result['status'], "success")
                        return redirect(url_for('trade'))  
                    else:
                        flash(result['status'], "danger")
                        return render_template('start_trade.html', 
                                               seller_teams=seller_teams, 
                                               seller_players=seller_players,
                                               your_players=your_players)

                return render_template('start_trade.html', 
                                       seller_teams=seller_teams, 
                                       seller_players=seller_players,
                                       your_players=your_players)
    except Exception as e:
        logging.error(f"Error in start_trade route: {e}")
        flash("An unexpected error occurred. Please try again later.", "danger")
        return redirect(url_for('dashboard'))

@app.route('/draft', methods=['GET'], endpoint='draft')
def draft():
    """
    Display all drafts from all leagues with pagination and an option to start a new draft.
    """
    # Retrieve query parameters
    order_by = request.args.get('order_by', 'Date')  # Default sorting by Date
    page = request.args.get('page', 1, type=int)    # Current page number

    # Define valid sorting fields
    valid_order_fields = ['Date', 'DraftOrder', 'DraftStatus', 'LeagueType']
    if order_by not in valid_order_fields:
        flash("Invalid sorting option. Please choose 'Date', 'DraftOrder', 'DraftStatus', or 'LeagueType'.", 'danger')
        order_by = 'Date'  # Reset to default

    # Define sorting SQL mapping
    sort_mapping = {
        'Date': 'Draft.DraftDate ASC',
        'DraftOrder': 'Draft.DraftOrder ASC',
        'DraftStatus': 'Draft.DraftStatus ASC',
        'LeagueType': 'League.LeagueType ASC'
    }
    sort_order = sort_mapping.get(order_by, 'Draft.DraftDate ASC')

    # Pagination settings
    drafts_per_page = 12
    offset = (page - 1) * drafts_per_page

    # Initialize variables to prevent UnboundLocalError
    drafts = []
    pagination = {
        'current_page': page,
        'total_pages': 1,
        'has_prev': False,
        'has_next': False,
        'prev_page': page - 1,
        'next_page': page + 1
    }

    # Establish database connection
    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:
            # Fetch total number of drafts for pagination
            cursor.execute("SELECT COUNT(*) AS count FROM Draft")
            total_drafts = cursor.fetchone()['count']
            total_pages = math.ceil(total_drafts / drafts_per_page) if total_drafts > 0 else 1
            pagination['total_pages'] = total_pages
            pagination['has_prev'] = page > 1
            pagination['has_next'] = page < total_pages

            # Fetch drafts with league information, sorting, and pagination
            drafts_query = f"""
                SELECT
                    Draft.DraftID,
                    Draft.DraftDate AS Date,
                    Draft.DraftOrder,
                    Draft.DraftStatus,
                    League.LeagueName,
                    League.LeagueType
                FROM Draft
                JOIN League ON Draft.LeagueID = League.LeagueID
                ORDER BY {sort_order}
                LIMIT %s OFFSET %s
            """
            cursor.execute(drafts_query, (drafts_per_page, offset))
            drafts = cursor.fetchall()

    except Exception as e:
        logging.error(f"Error fetching drafts: {e}")
        flash("An error occurred while fetching drafts. Please try again later.", "danger")
    finally:
        connection.close()

    return render_template(
        'draft.html',
        drafts=drafts,
        order_by=order_by,
        pagination=pagination
    )



@app.route('/draft/new', methods=['GET', 'POST'], endpoint='new_draft')
def new_draft():
    """
    handle the creation of a new draft
    """
    if request.method == 'POST':
        # get the form data
        league_id = request.form.get('league_id', type=int)
        draft_order = request.form.get('draft_order')  # 'R' 或 'S'

        # validate the form data
        if not league_id or draft_order not in ['R', 'S']:
            flash("请选择有效的联盟和草稿顺序。", "danger")
            return redirect(url_for('new_draft'))

        # use current date as DraftDate
        draft_date = datetime.today().date()

        # establish a database connection
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                cursor.callproc('StartDraft', [league_id, draft_date, draft_order])

                # get the DraftID of the new draft
                row = cursor.fetchone()
                if row and 'DraftID' in row:
                    draft_id = row['DraftID']
                    flash("Successfully started a new draft", "success")
                    return redirect(url_for('draft_detail', draft_id=draft_id))
                else:
                    flash("Fail to get the ID of new draft", "danger")
                    return redirect(url_for('new_draft'))

        except pymysql.MySQLError as e:
            # handle custom error messages
            if e.args[0] == 45000:
                flash(e.args[1], "danger")
            else:
                logging.error(f"Error when starting new draft: {e}")
                flash("Error when starting new draft, please try again later", "danger")
            return redirect(url_for('new_draft'))
        finally:
            connection.close()
    else:
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                # get the list of leagues
                cursor.execute("""
                    SELECT LeagueID, LeagueName, LeagueType
                    FROM League
                    ORDER BY LeagueName ASC
                """)
                leagues = cursor.fetchall()
        except Exception as e:
            logging.error(f"Error when getting league list: {e}")
            flash("Error when getting league list, please try again later", "danger")
            leagues = []
        finally:
            connection.close()

        return render_template('new_draft.html', leagues=leagues)

@app.route('/draft/<int:draft_id>', methods=['GET'], endpoint='draft_detail')
def draft_detail(draft_id):
    """
    Display the details of a specific draft, including the league name, draft date, order, status, and assigned players.
    """
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            # get the draft details
            cursor.execute("""
                SELECT
                    Draft.DraftID,
                    Draft.DraftDate,
                    Draft.DraftOrder,
                    Draft.DraftStatus,
                    League.LeagueName,
                    League.LeagueType
                FROM Draft
                JOIN League ON Draft.LeagueID = League.LeagueID
                WHERE Draft.DraftID = %s
            """, (draft_id,))
            draft = cursor.fetchone()

            if not draft:
                flash("Draft not found", "danger")
                return redirect(url_for('draft'))

            # get the players assigned to the draft
            cursor.execute("""
                SELECT
                    Player.PlayerID,
                    Player.FullName,
                    Player.Position,
                    Player.FantasyPoints,
                    Team.TeamName
                FROM Player
                JOIN Team ON Player.TeamID = Team.TeamID
                WHERE Player.DraftID = %s
                ORDER BY Team.TeamName ASC, Player.FantasyPoints DESC
            """, (draft_id,))
            players = cursor.fetchall()

    except Exception as e:
        logging.error(f"Error when getting draft details: {e}")
        flash("Errors when getting draft details, please try again later", "danger")
        return redirect(url_for('draft'))
    finally:
        connection.close()

    return render_template('draft_detail.html', draft=draft, players=players)


# Waiver routes
@app.route('/waivers', methods=['GET'])
def waiver_list():
    """
    Display all currently available Waiver players, with sorting options.
    """
    sort_order = request.args.get('sort', 'Name')  # Default to 'Name' if not specified

    # Validate sort_order parameter
    valid_sort_orders = ['Name', 'Sport', 'FantasyPoints']
    if sort_order not in valid_sort_orders:
        sort_order = 'Name'

    # Check if user is admin
    is_admin = False
    if 'user_id' in session:
        connection = get_db_connection()
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT Position FROM User WHERE UserID = %s", (session['user_id'],))
                user = cursor.fetchone()
                if user and user['Position'] == 'A':
                    is_admin = True
        except pymysql.MySQLError as e:
            logger.error(f"Error checking user position: {e}")
        finally:
            connection.close()

    connection = get_db_connection()
    try:
        with connection.cursor(pymysql.cursors.DictCursor) as cursor:
            # Call the stored procedure GetWaiverPlayers
            cursor.callproc('GetWaiverPlayers', (sort_order,))

            # Fetch all results
            players = []
            while True:
                result = cursor.fetchall()
                if result:
                    players.extend(result)
                if not cursor.nextset():
                    break
    except pymysql.MySQLError as e:
        logger.error(f"Error fetching waiver players: {e}")
        flash("Error fetching Waiver player list, please try again later.", "danger")
        players = []
    finally:
        connection.close()

    return render_template('waiver_list.html', players=players, sort_order=sort_order, is_admin=is_admin)

@app.route('/waivers/<int:waiver_id>', methods=['GET'])
def waiver_details(waiver_id):
    """
    Display the details of a specific Waiver.
    """
    # Check if user is admin
    is_admin = session.get('is_admin', False)

    connection = get_db_connection()
    try:
        with connection.cursor(pymysql.cursors.DictCursor) as cursor:
            # Call the stored procedure GetWaiverDetails
            cursor.callproc('GetWaiverDetails', (waiver_id,))

            # Fetch the first result
            waiver = cursor.fetchone()
            while waiver is None and cursor.nextset():
                waiver = cursor.fetchone()

            if not waiver:
                flash(f"Details for Waiver ID {waiver_id} not found.", "warning")
                return redirect(url_for('waiver_list'))
    except pymysql.MySQLError as e:
        logger.error(f"Error fetching waiver details: {e}")
        flash("Error fetching Waiver details, please try again later.", "danger")
        return redirect(url_for('waiver_list'))
    finally:
        connection.close()

    return render_template('waiver_details.html', waiver=waiver, is_admin=is_admin)

@app.route('/waivers/<int:waiver_id>/update', methods=['GET', 'POST'])
def update_waiver_status(waiver_id):
    """
    Update the status (approve or deny) of a specific Waiver.
    """
    # Check if user is logged in
    if 'user_id' not in session:
        flash("Please log in first.", "danger")
        return redirect(url_for('login'))

    # Check if user is admin
    is_admin = False
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT Position FROM User WHERE UserID = %s", (session['user_id'],))
            user = cursor.fetchone()
            if user and user['Position'] == 'A':
                is_admin = True
            else:
                flash("You do not have permission to perform this action.", "danger")
                return redirect(url_for('waiver_list'))
    except pymysql.MySQLError as e:
        logger.error(f"Error checking user permissions: {e}")
        flash("Error checking permissions, please try again later.", "danger")
        return redirect(url_for('waiver_list'))
    finally:
        connection.close()

    if request.method == 'POST':
        new_status = request.form.get('status')

        # Validate new_status
        valid_statuses = ['A', 'D']  # A: Approved, D: Denied
        if new_status not in valid_statuses:
            flash("Invalid status option.", "danger")
            return redirect(url_for('update_waiver_status', waiver_id=waiver_id))

        connection = get_db_connection()
        try:
            with connection.cursor(pymysql.cursors.DictCursor) as cursor:
                # Call the stored procedure UpdateWaiverStatus
                cursor.callproc('UpdateWaiverStatus', (waiver_id, new_status))
                connection.commit()

                # Fetch the result message
                result = cursor.fetchone()
                while result is None and cursor.nextset():
                    result = cursor.fetchone()

                if result and 'UpdateMessage' in result:
                    update_message = result['UpdateMessage']
                    flash(update_message, "success")
                else:
                    flash("Waiver status has been updated.", "success")
        except pymysql.MySQLError as e:
            logger.error(f"Error updating waiver status: {e}")
            flash("Error updating Waiver status, please try again later.", "danger")
            return redirect(url_for('waiver_details', waiver_id=waiver_id))
        finally:
            connection.close()

        return redirect(url_for('waiver_details', waiver_id=waiver_id))
    else:
        # GET request, display the update form
        connection = get_db_connection()
        try:
            with connection.cursor(pymysql.cursors.DictCursor) as cursor:
                cursor.callproc('GetWaiverDetails', (waiver_id,))
                waiver = cursor.fetchone()
                while waiver is None and cursor.nextset():
                    waiver = cursor.fetchone()
                if not waiver:
                    flash(f"Details for Waiver ID {waiver_id} not found.", "warning")
                    return redirect(url_for('waiver_list'))
        except pymysql.MySQLError as e:
            logger.error(f"Error fetching waiver details for update: {e}")
            flash("Error fetching Waiver details, please try again later.", "danger")
            return redirect(url_for('waiver_list'))
        finally:
            connection.close()

        return render_template('update_waiver.html', waiver=waiver)



if __name__ == '__main__':
    app.run(debug=True)