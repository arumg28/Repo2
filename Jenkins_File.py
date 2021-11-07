import argparse
import zlib
import getpass
from base64 import urlsafe_b64encode as b64e, urlsafe_b64decode as b64d


parser = argparse.ArgumentParser(description='This function is for Password Encryption')
parser.add_argument("--password", default=None, type=str, help="Your password")

args = parser.parse_args()
password = args.password

def encode_credentials(data):
    data=bytes(data, encoding='utf8')
    return bytes (b64e(zlib.compress(data,9)))

def Decrypt_Password(password):
    credentials = zlib.decompress(b64d(password))
    credentials = credentials.decode('utf-8')
    print("Decrypted Password is: {}".format(credentials))


if __name__ == '__main__':
    #password = str(getpass.getpass(prompt="Enter Password"))
    ##password = 'arun@1234'
    encoded_password=encode_credentials(password)
    print("Encoded Password: {}".format(encoded_password))
    Decrypt_Password(encoded_password)



