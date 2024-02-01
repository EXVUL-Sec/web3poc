# web3poc


### This is EXVUL Web3 attack PoC 

- #### 20240112 WiseLending  ATTACK 
  - see the details:
    -  https://twitter.com/EXVULSEC/status/1746138811862577515
    
    PoC: [WiseLending.sol](./WiseLending/WiseLending.sol)
    ```
    forge test --contracts ./WiseLending/WiseLending.sol -vvv --evm-version shanghai
    ```


- #### 20240130 MIM_SPELL  ATTACK 
  - see the details:
    -  https://twitter.com/EXVULSEC/status/1752288206211690578
    
    PoC: [MIMSpell_Attack.sol](./MIM/MIMSpell_Attack.sol)
    ```
    forge test --contracts ./MIM/MIMSpell_Attack.sol -vvv --evm-version shanghai
    ```
