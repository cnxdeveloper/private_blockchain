# Create Your Own Private Blockchain 
Author: chungnx
## Install library and run application
```bash
sudo apt install nodejs
sudo apt install npm
cd private_blockchain
npm install .
node app.js
```
[Postman api file](PostmanAPi.json)
## Screenshot result:


GET: http://localhost:8000/block/height/0
![](images/get_block_by_height.png)

POST: http://localhost:8000/requestValidation
![](images/request_validation.png)

Sign Message:
![](images/signed_images.png)

POST: http://localhost:8000/submitstar
![](images/submitstar.png)

GET: http://localhost:8000/blocks/mhJjL6eR2HL5PrSmAjSZ2ze8pCNviV5J6U
![](images/retrive_blocks_with_address.png)

GET: http://localhost:8000/blocks/mhJjL6eR2HL5PrSmAjSZ2ze8pCNviV5J6U
![](images/retrive_block_with_hash.png)





