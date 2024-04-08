net user Administrator /active:no
net user Guest /active:no
net user DefaultAccount /active:no
net user WDAGUtilityAccount /active:no

wmic useraccount where "name='Administrator'" rename gmoment
wmic useraccount where "name='Guest'" rename robert

wmic UserAccount set PasswordExpires=True
wmic UserAccount set Lockout=False
