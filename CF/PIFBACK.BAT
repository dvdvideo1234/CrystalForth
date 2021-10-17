IF EXIST ..\..\PIF.COM (
  COPY ..\..\PIF.COM *.COM  > NUL
  PIF2 BYE
  COPY PIF.COM ..\..\PIF.COM
)
