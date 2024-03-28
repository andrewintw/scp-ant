# scp-ant

透過 scp 搬移一堆檔案的小工具


## WHY | 使用情境

```
         TRGET BOARD                                         BUILD SYSTEM
+----------------------------+                       +-------------------------+
| - /usr/local/lib/libxxx.so |====== (network) ======| /sdk/target/rootfs      |
| - /etc/config/xxx.conf     |                       | ├── etc/...             |
| - ...                      |                       | └── usr                 |
+----------------------------+                       |     └── local           |
                                                     |          `── lib/...    |
                                                     +-------------------------+
```

在嵌入式系統領域開發新功能時，有時我們會直接在某一台 target 設備上直接實作新功能。當功能完成後，就得將開發過程中變動的檔案取出交給編譯系統（或者說 SDK）。這樣下回由編譯系統產生的韌體就會有這個新功能。

我通常使用 scp 將裝置中更新的檔案，一個個複製到編譯主機上的某個目錄 ex: `/home/ant/target/rootfs`，並且建立相對應的資料夾目錄階層。複製完成後，在 rootfs/ 下就可以看見所有的檔案、目錄結構。如果你曾經解開過 deb 套件，你應該可以理解我所說的目錄樹結構是什麼。完成後，可以選擇將整個 rootfs tar 起來做成解壓安裝包，或是交給 build sysem 的維護者安裝到 sdk 目錄中。

因為這些檔案可能分散在檔案系統中的不同目錄，如果要一個個處理，會花許多時間。


## WHAT | scp-ant 在幹嘛

簡單說，就是你給他一個檔案清單，scp-ant 就會幫你複製到遠端主機中的某個目錄，並且建立出一樣的資料夾結構。

scp-ant 只是一支簡單的 bash script。使用前，您需要根據你的環境，修改程式碼中的變數，改成你的目標主機資訊即可。

```
rmt_host="你的 ssh-server ip 地址"
rmt_user="登入 ssh-server 的帳號"
rmt_port="ssh 使用的 port"
rmt_basedir="想要將檔案複製到哪個資料夾下"
sshpass_passwd="ssh 登入密碼"
```

file_list 則是條列出你想要從裝置端取出，並傳送到遠端主機目錄內的檔案清單。

```
file_list="
	/usr/include/xxx.h
	/usr/local/lib/libxxx.so
	/usr/local/sbin/dispatcher.sh
	/root/.ssh/authorized_keys
	/etc/config/xxx.conf
	/no/such/file.txt    # 這裡刻意寫了一個不存在的檔案
"
```

設定好後，執行 scp-ant，程式就會一一解析你想要複製的檔案路徑清單，例如:

若發現你要傳送 `/usr/local/lib/libxxx.so`，就會先在遠端主機的 `/home/ant/target/rootfs` 目錄下先建立 `usr/local/lib` 資料夾，接著將 libxxx.so 以 scp 複製過去。


## DEMO | 執行方式

目前遠端主機的目錄是空的:

```
$ tree -a /home/ant/target/rootfs
/home/ant/target/rootfs

0 directories, 0 files

```

將 scp-ant.sh 複製到裝置端，設定好變數和 file_list 清單:

```
file_list="
	/usr/include/utils.h
	/usr/local/lib/libtest.so
	/usr/local/sbin/agent
	/usr/local/sbin/dispatcher.sh
	/root/.ssh/authorized_keys
	/root/.ssh/id_rsa
	/etc/config/teleport
	/usr/local/sbin/gentunnel
	/no/such/file.txt           # 這裡刻意寫了一個不存在的檔案
	/etc/init.d/diag
	/etc/init.d/agent
"
```

執行:

```
# ./scp-ant.sh
MKDIR> /usr/include
SCP>   /usr/include/utils.h -> 10.1.1.123
MKDIR> /usr/local/lib
SCP>   /usr/local/lib/libtest.so -> 10.1.1.123
MKDIR> /usr/local/sbin
SCP>   /usr/local/sbin/agent -> 10.1.1.123
MKDIR> /usr/local/sbin
SCP>   /usr/local/sbin/dispatcher.sh -> 10.1.1.123
MKDIR> /root/.ssh
SCP>   /root/.ssh/authorized_keys -> 10.1.1.123
MKDIR> /root/.ssh
SCP>   /root/.ssh/id_rsa -> 10.1.1.123
MKDIR> /etc/config
SCP>   /etc/config/teleport -> 10.1.1.123
MKDIR> /usr/local/sbin
SCP>   /usr/local/sbin/gentunnel -> 10.1.1.123
ERRO>  NO such file: /no/such/file.txt          # 有被檢查出來
MKDIR> /etc/init.d
SCP>   /etc/init.d/diag -> 10.1.1.123
MKDIR> /etc/init.d
SCP>   /etc/init.d/agent -> 10.1.1.123
DONE :)
```

執行完後遠端主機內的 /home/ant/target/rootfs 目錄內就有所有檔案了:

```
$ tree -a /home/ant/target/rootfs/
/home/ant/target/rootfs/
├── etc
│   ├── config
│   │   └── teleport
│   └── init.d
│       ├── agent
│       └── diag
├── root
│   └── .ssh
│       ├── authorized_keys
│       └── id_rsa
└── usr
    ├── include
    │   └── utils.h
    └── local
        ├── lib
        │   └── libtest.so
        └── sbin
            ├── agent
            ├── dispatcher.sh
            └── gentunnel

10 directories, 10 files
```

