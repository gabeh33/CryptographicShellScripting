# CryptographicShellScripting
Building a functional digital envelope using Bash scripting

## Usage
To encrypt a file and seal it in a digital envelope, use the command 
```
./crypto.sh -e receiver1.pub receiver2.pub receiver3.pub sender.priv <plaintext_file> <encrypted_file>
```
The encrypted file will be a .zip file containing all the files created by a digital envelope.

To decrypt a file using one of the recievers private keys, use the command 
```
./crypto.sh -d recierver<#>.priv sender.pub <encrypted_file> <decrypted_file>
```

### Notes
You can generate your own public/private/symmetric keys using whatever method you like, 
however they must be named 
```
receiver1.pub, receiver1.priv
receiver2.pub, receiver2.priv
receiver3.pub, receiver3.priv
sender.pub, sender.priv
```
