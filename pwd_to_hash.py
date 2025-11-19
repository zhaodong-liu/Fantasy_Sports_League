from werkzeug.security import generate_password_hash
while True:
    plain_password = input('Enter your password: ')
    hashed_password = generate_password_hash(plain_password, method='pbkdf2:sha256', salt_length=16)
    print(hashed_password)
    print()