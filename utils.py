import pymysql
import logging
from typing import List, Dict, Union


def GetMatches(connection, sport, order_by):
    with connection.cursor() as cursor:
        cursor.callproc('GetMatches', (sport, order_by))
        result = cursor.fetchall()
        return result
    

def GetMatchEvents(connection, match_id, order_by):
    with connection.cursor() as cursor:
        cursor.callproc('GetMatchEvents', (match_id, order_by))
        result = cursor.fetchall()
        return result




def GetAllPlayerStats(connection, order_by):
    """
    Fetch all player stats using the GetAllPlayerStats stored procedure, sorted by the specified order.
    """
    with connection.cursor() as cursor:
        try:
            # call the stored procedure
            cursor.callproc('GetAllPlayerStats', [order_by])
            # fetch all rows of data
            result = cursor.fetchall()
            return result
        except pymysql.MySQLError as e:
            # handle MySQL errors
            if e.args[0] == 45000:
                # stored procedure error
                raise ValueError(e.args[1])
            else:
                # general MySQL error
                raise e

def GetPlayerDetails(conn, player_id):
    """
    Retrieves details of a player by calling the GetPlayerDetails stored procedure.
    
    :param conn: MySQL connection object.
    :param player_id: The ID of the player whose details you want to retrieve.
    :return: A dictionary containing the player's details or error message.
    """
    cursor = conn.cursor(pymysql.cursors.DictCursor)  # DictCursor

    cursor.callproc('GetPlayerDetails', (player_id,))
    data = cursor.fetchone()

    if data:
        result = data  # Directly return the dictionary for the player details
    else:
        result = {'ErrorMessage': 'Player not found.'}

    cursor.close()
    
    return result



# def GetPlayerStatus(conn, league_id, sort_by):
#     """
#     Retrieves player status for a given league by calling the GetPlayerStatus stored procedure.
    
#     :param conn: MySQL connection object.
#     :param league_id: The ID of the league whose player status is to be retrieved.
#     :param sort_by: The field to sort by ('name', 'sport', or 'fantasy points').
#     :return: A list of dictionaries containing player details or an error message.
#     """
#     cursor = conn.cursor(pymysql.cursors.DictCursor)  # Ensure DictCursor is used
    
#     # Call the stored procedure with the provided parameters
#     cursor.callproc('GetPlayerStatus', (league_id, sort_by))
    
#     # Fetch all rows of data
#     data = cursor.fetchall()

#     # Close the cursor
#     cursor.close()

#     # Return the data (or an error message if no data is found)
#     if data:
#         return data
#     else:
#         return {'ErrorMessage': 'No players found for the given league.'}
    


# def GetPlayerStatusByID(conn, player_id):
#     """
#     Retrieves the status of a player by calling the GetPlayerStatusByID stored procedure.
    
#     :param conn: MySQL connection object.
#     :param player_id: The ID of the player whose status you want to retrieve.
#     :return: A dictionary containing the player's details or error message.
#     """
#     cursor = conn.cursor(pymysql.cursors.DictCursor)  # Use DictCursor
    
#     cursor.callproc('GetPlayerStatusByID', (player_id,))
    
#     data = cursor.fetchone()
#     cursor.close()
    
#     # Check if data exists (i.e., player found)
#     if data:
#         return data  # Return the player details as a dictionary
#     else:
#         return {'ErrorMessage': 'Player not found.'}
    


def GetTrades(conn, order_by_field):
    """
    Retrieves all trades by calling the GetTrades stored procedure.

    :param conn: MySQL connection object.
    :param order_by_field: The field to order results by ('Name', 'Sport', or 'Fantasy Points').
    :return: A list of dictionaries containing the query results.
    """
    cursor = conn.cursor(pymysql.cursors.DictCursor)  # Use DictCursor
    
    cursor.callproc('GetTrades', (order_by_field,))
    
    data = cursor.fetchall()

    cursor.close()
    
    return data

def ExecuteTrade(connection, user_id, seller_team_id, player_id, your_player_id, trade_date):
    """
    Executes a trade between two players by calling the ExecuteTrade stored procedure.
    """
    try:
        with connection.cursor() as cursor:
            # call the stored procedure
            cursor.callproc('ExecuteTrade', (user_id, seller_team_id, player_id, your_player_id, trade_date))
            connection.commit()
            return {'status': "Trade executed successfully."}
    except pymysql.err.InternalError as e:
        # handle stored procedure errors
        error_code, error_message = e.args
        logging.error(f"Stored Procedure Error {error_code}: {error_message}")
        return {'status': error_message}
    except Exception as e:
        # handle unexpected errors
        connection.rollback()
        logging.error(f"Unexpected Error: {e}")
        return {'status': "An unexpected error occurred while executing the trade."}
    
    
def start_draft(conn, league_id, draft_date, draft_order):
    """
    Starts a draft for a given league by calling the StartDraft stored procedure.
    
    :param conn: MySQL connection object.
    :param league_id: The ID of the league to start the draft for.
    :param draft_date: The date when the draft starts.
    :param draft_order: The draft order type ('R' for round-robin, 'S' for snake).
    """
    cursor = conn.cursor()

    cursor.callproc('StartDraft', (league_id, draft_date, draft_order))
    conn.commit()

    cursor.close()