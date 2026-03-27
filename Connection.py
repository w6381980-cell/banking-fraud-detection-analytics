# import pandas as pd
# from sqlalchemy import create_engine

# # Connection string (SQL Server)
# server = 'localhost'
# database = 'BankingDB'

# engine = create_engine(f'mssql+pyodbc://{server}/{database}?driver=ODBC+Driver+17+for+SQL+Server')

# print("Connection Successful")


# query = "SELECT * FROM Transactions"

# df = pd.read_sql(query, engine)

# print(df.head())


# print(df.info())
# print(df.describe())

# # Missing values check
# print(df.isnull().sum())

# # Convert date_time to datetime
# df['date_time'] = pd.to_datetime(df['date_time'])


# def detect_fraud(row):
#     if row['amount'] > 50000:
#         return 1
#     else:
#         return 0

# df['fraud_flag'] = df.apply(detect_fraud, axis=1)


# df = df.sort_values(['customer_id', 'date_time'])

# df['prev_amount'] = df.groupby('customer_id')['amount'].shift(1)

# def advanced_fraud(row):
#     if row['amount'] > 50000:
#         return 1
#     elif row['prev_amount'] and row['amount'] > row['prev_amount'] * 3:
#         return 1
#     else:
#         return 0

# df['fraud_flag'] = df.apply(advanced_fraud, axis=1)


# def fraud_reason(row):
#     if row['amount'] > 50000:
#         return "High Transaction Amount"
#     elif row['prev_amount'] and row['amount'] > row['prev_amount'] * 3:
#         return "Sudden Spike"
#     else:
#         return "Normal"

# df['reason'] = df.apply(fraud_reason, axis=1)

# fraud_df = df[['transaction_id', 'fraud_flag', 'reason']]

# fraud_df.to_sql('FraudFlags', engine, if_exists='append', index=False)


# import time

# while True:
#     print("Running Fraud Detection...")
    
#     df = pd.read_sql("SELECT * FROM Transactions", engine)
    
#     # logic run
#     df['fraud_flag'] = df['amount'].apply(lambda x: 1 if x > 50000 else 0)
    
#     fraud_df = df[['transaction_id', 'fraud_flag']]
    
#     fraud_df.to_sql('FraudFlags', engine, if_exists='replace', index=False)
    
#     print("Done ")
    
#     time.sleep(86400)  # 24 hours


import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "mssql+pyodbc://@LAPTOP-LG4BEQ1J\\SQLEXPRESS/BankingDB?driver=ODBC+Driver+17+for+SQL+Server"
)

print("Connected")

df = pd.read_sql("SELECT * FROM Transactions", engine)
print(df.head())

# Convert date
df['date_time'] = pd.to_datetime(df['date_time'])

# Sort + previous transaction
df = df.sort_values(['customer_id', 'date_time'])
df['prev_amount'] = df.groupby('customer_id')['amount'].shift(1)

# Fraud detection
df['fraud_flag'] = 0

df.loc[df['amount'] > 50000, 'fraud_flag'] = 1

df.loc[
    (df['prev_amount'].notnull()) & 
    (df['amount'] > df['prev_amount'] * 3),
    'fraud_flag'
] = 1

# Reason
df['reason'] = "Normal"
df.loc[df['amount'] > 50000, 'reason'] = "High Transaction Amount"
df.loc[
    (df['prev_amount'].notnull()) & 
    (df['amount'] > df['prev_amount'] * 3),
    'reason'
] = "Sudden Spike"

# Save to SQL
fraud_df = df[['transaction_id', 'fraud_flag', 'reason']]

fraud_df.to_sql('FraudFlags', engine, if_exists='replace', index=False)

print("Fraud Detection Completed ")