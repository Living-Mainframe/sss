;;; sss example config
;; all parameters are optional, unless specified
{:servers
  {:example1 {:ip :1.2.3.4      ; or hostname (required)
              :user :root       ; ssh username
              :pass :adcdd      ; ssh password
              :bg :0000ff       ; background color
              :env :TERM=xterm  ; modify the environment
              :opts ""          ; additional ssh options
              :vpn :ExampleVPN} ; start this NetworkManager connection
   :3270 {:ip :zos.example          ; required
          :type :c3270              ; required to use c3270 for this connection
          :opts "3270 -defaultfgbg" ; additional c3270 options
          :bg :000000}
   :wazi {:ip :cloud.example        ; required
          :sleep :8m                ; wait 8 minutes between starting the instances and connecting
          :ibmcloud {:apikey ""                     ; ibmcloud api key
                     :instances [:server1 :server2] ; start (and stop) these instances
                     :stop false}}}}                ; don't stop the started instances
