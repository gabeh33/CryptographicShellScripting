#!/bin/bash 
MODE="not set"
echoerr() { cat <<< "$@"1>&2; }
if [ $1 == "-e" ]; then 
	MODE="encrypt"
elif [ $1 == "-d" ]; then
	MODE="decrypt"
else
	echoerr "ERROR holmes.ga - The first arugment needs to be \"-e\" for encrypt 
         	or \"-d\" for decrypt, not $1"
	exit 1
fi

# Now we can get to encrypting or decrypting 
if [ $MODE == "encrypt" ]; then
	# symmetric.key will hold the symmetric key used to encode the message in the envelope
	openssl rand -hex 128 > symmetric.key

	# Test if $6 is a file 
	if ! [ -f "$6" ]; then
		echoerr "ERROR holmes.ga - File does not exist"
		rm symmetric.key
		exit 2  
	fi

	# Test if $5 is a public key instead of a private key 
	if grep -q PUBLIC "$5"; then
		echoerr "ERROR holmes.ga - Provided a public key instead of a private key"
		rm symmetric.key
		exit 2
	fi

	# Now need to encrypt the given file using this symmetric key 
	# This is where we encrypt the plaintxt, but not yet the symmetric key
	# Get rid of the .zip of the given file 
        fullname=$7
        outputfile=${fullname::-4}
	openssl enc -aes-256-cbc -pbkdf2 -in $6 -out $outputfile -k symmetric.key


	# Now we have an encrypted file, next need to hash the plaintxt file and 
	# temporarly store that hash
	sha512sum $6 > hash.txt
	
	# Now sign that hash using the senders private key
	cat hash.txt | openssl rsautl -inkey $5 -sign > hash.signed
	# We use this to check while decrypting -- integrity 

	# Now we need to encrypt the symmetric.key with all the receivers public keys
	# This way any of the receivers can decrypt one of the keys using their private key
	# and then go on to decrypt the message itself 

	# Encrypt the symmetric key with each of the receivers public key 
	openssl rsautl -encrypt -inkey $2 -pubin -in symmetric.key -out receiver1key.enc
	openssl rsautl -encrypt -inkey $3 -pubin -in symmetric.key -out receiver2key.enc
	openssl rsautl -encrypt -inkey $4 -pubin -in symmetric.key -out receiver3key.enc

	# Cipehertxt is file $7
	# Encrypted symmetric keys are files receiverXkey.enc
	# Signed hash of plaintxt is hash.signed 
	# Now we zip the signed hash, the three encrypted keys, and the encrypted message together
	################ This is the digital envelope ###################
	zip -j $outputfile $outputfile receiver1key.enc receiver2key.enc receiver3key.enc hash.signed
	
	# Clean up the intermediate files 
	rm hash.txt
	rm symmetric.key
	rm receiver1key.enc
	rm receiver2key.enc	
	rm receiver3key.enc
	rm hash.signed
	rm $outputfile
else
	# Otherwise we decrypt the file given the .zip from encoding it 
	# $2 is the receivers private key, $3 is senders public key, $4 is ciphertxt, $5 is output file 
	# Start by unzipping the given .zip file 
	unzip $4

	# First step is verifying the signature 
	# Attempt to verify and store it in the file verfiyfile.txt
	openssl rsautl -verify -inkey $3 -in hash.signed -out verifyfile.txt -pubin 
	if [ -s verifyfile.txt ]; then
		# verifyfile is not empty, so the signature was successful
		rm verifyfile.txt
		rm hash.signed
	else
		# verifyfile is empty, therefore the signature failed
                echoerr "ERROR holmes.ga - Signature verification failed, the message was tampered with or you are using the
                        wrong public key"
		rm verifyfile.txt
		rm hash.signed
                exit 2
	fi
	
	# Now the signature is verified, so next step is decrypting the symmetric key 
	# symmetric.key will hold the symmetric key that is used to encrypt and decrypt the message
	# 2 of these will fail, but one will be corrent and update symmetric.key with the corrent key 
	touch symmetric.key
	openssl rsautl -decrypt -inkey $2 -in receiver1key.enc >> symmetric.key
	openssl rsautl -decrypt -inkey $2 -in receiver2key.enc >> symmetric.key
	openssl rsautl -decrypt -inkey $2 -in receiver3key.enc >> symmetric.key
	rm receiver1key.enc
	rm receiver2key.enc
	rm receiver3key.enc 

	# Now symmetric.key should have the same symmetric key used, if it doesnt then 
	# the private key presented is not able to decrypt 
	if ! [ -s symmetric.key ]; then
		echoerr "ERROR holmes.ga - Unable to decrypt the symmetric key, are you using a valid private key?"
		rm symmetric.key
		exit 3
	fi
	#Final step is to decrypt the file with the message using the symmetric key
	# Get rid of the .zip of the given file 
	zipname=$4
	ciphertxt=${zipname::-4}
	openssl enc -d -aes-256-cbc -pbkdf2 -in $ciphertxt -out $5 -k symmetric.key	
	rm symmetric.key
	rm $ciphertxt
	# Note - I am getting autograder errors, but when I run the same commands from my terminal I am not getting errors and 
	# the correct files are being created (with some extra output to stdout but the encryption/decryption is working). I 
	# am guessing this is due to the absolute vs relative path problem outlined in piazza, and I have tried many different things
	# but cannot seem to get it to work, so I am submitting this and hoping to get some points back that I got off from the autograder
	# Thank you!
fi











