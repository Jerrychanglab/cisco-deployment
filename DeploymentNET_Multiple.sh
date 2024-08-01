#!/bin/bash
password=`cat /home/jarry_chang/ntp/.pw`
switchuser="procni"
#畫面清空
clear
function login() {
    #==== 功能選擇> GO
    while true; do
        echo -e $'\e[1;97;44m【 功能 - 選擇 】\e[0m '
        echo "▶ vxlan - 設定 "
        echo "▶ 未定義 - 設定 "
        echo -n -e "\033[1;31m ❯ 填寫: \033[0m"
        read ChooseFunction
        ######## vxlan配置
        if [ "${ChooseFunction,,}" = "vxlan" ]; then
            while true; do
                echo -e $'\e[1;97;44m【 動作 - 選擇 】\e[0m '
                echo "▶ Add "
                echo "▶ Del "
                echo -n -e "\033[1;31m ❯ 填寫: \033[0m"
                read ChooseVxLanStat
                # vxlan新增
                if [ "${ChooseVxLanStat,,}" = "add" ]; then
                    # switch - IP 填寫
                    echo -e $'\e[1;97;44m【 Switch IP - 填寫 】\e[0m '
                    while true; do
                        echo -n -e "\033[1;31m ❯ 填寫: \033[0m"
                        read SwitchIps
                        IFS=',' read -r -a SwitchIpArray <<< "$SwitchIps"
                        allValid=true
                        for ip in "${SwitchIpArray[@]}"; do
                            if ! [[ $ip =~ ^10\.252\.252\.[0-9]+$ ]]; then
                                echo -e "\033[31m ( 無效輸入，規則 10.252.252.X ) \033[0m "
                                allValid=false
                                break
                            fi
                        done
                        if $allValid; then
                            break
                        fi
                    done
                    # vxlan - vlan 填寫
                    echo -e $'\e[1;97;44m【 vLan ID - 填寫 】\e[0m '
                    while true; do
                        echo -n -e "\033[1;31m ❯ 填寫: \033[0m"
                        read vLanID
                        if [[ $vLanID =~ ^([1-9][0-9]{0,2}|[1-3][0-9]{3}|40[0-8][0-9]|409[0-4])$ ]]; then
                            vLanIdExists=false
                            for ip in "${SwitchIpArray[@]}"; do
                                vLanIdCheck=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${switchuser}@${ip} "show vlan brief | include $vLanID | awk '{print \$1}'" 2>/dev/null)
                                if [[ -n $vLanIdCheck ]]; then
                                    vLanIdExists=true
                                    echo -e "\033[31m ( vLan ID ${vLanID} 在 ${ip} [已]存在，請先進行[移除] ) \033[0m "
                                fi
                            done
                            if ! $vLanIdExists; then
                                break
                            else
                                echo -e "\033[31m ( 請離開此介面Ctrl+C，或執行其他vLan ID) \033[0m "
                            fi
                        else
                            echo -e "\033[31m ( 無效輸入，規則 1-4096 ) \033[0m "
                        fi
                    done
                    # vxlan - name 填寫
                    echo -e $'\e[1;97;44m【 vLan Name - 填寫 】\e[0m '
                    while true; do
                        echo -n -e "\033[1;31m ❯ 填寫: \033[0m"
                        read NameRule
                        if [[ $NameRule =~ ^[a-zA-Z0-9_-]{1,10}$ ]]; then
                            break
                        else
                            echo -e "\033[31m ( 無效輸入，規則 英文/數字/-_，不能超過10位數 ) \033[0m "
                        fi
                    done
                    #vxlan檢查
                    declare -A LoopBackIps
                    for ip in "${SwitchIpArray[@]}"; do
                        LoopBackIp=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${switchuser}@${ip} "show running-config interface loopback 0 | begin 'ip address' | head -n 1 | sed 's/ip address //; s/\/.*//' | sed 's/^[[:space:]]*//'" 2>/dev/null)
                        LoopBackIps["$ip"]="$LoopBackIp"
                    done

                    clear
                    echo "========================================================="
                    echo -e $'\e[1;97;44m【 新增 - 參數檢查 】\e[0m '
                    for ip in "${!LoopBackIps[@]}"; do
                        echo -e "\e[32m✔\e[0m Switch IP ➜ \e[1;31m ${ip}\e[0m LoopBack IP ➜ \e[1;31m ${LoopBackIps["$ip"]}\e[0m"
                    done
                    echo -e "\e[32m✔\e[0m vLan ID ➜ \e[1;31m $vLanID\e[0m"
                    echo -e "\e[32m✔\e[0m vLan Name ➜ \e[1;31m $NameRule\e[0m"
                    echo -e "\e[32m✔\e[0m vni member ➜ \e[1;31m 22$vLanID\e[0m"
                    echo "========================================================="
                    echo ""
                    echo -e $'\e[1;97;33m 檢查完成? 執行部署?  \e[0m '
                    echo "▶ Yes"
                    echo "▶ No"
                    while true; do
                        echo -n -e "\033[1;31m ❯ 填寫: \033[0m"
                        read confirm
                        if [ "${confirm,,}" = "yes" ]; then
                            break
                        elif [ "${confirm,,}" = "no" ]; then
                            break
                        else
                            echo -e "\033[31m ( 無效輸入，請輸入'Yes' 'No' ) \033[0m "
                        fi
                    done
                    break
                elif [ "${ChooseVxLanStat,,}" = "del" ]; then
                    # switch - IP 填寫
                    echo -e $'\e[1;97;44m【 Switch IP - 填寫 】\e[0m '
                    while true; do
                        echo -n -e "\033[1;31m ❯ 填寫: \033[0m"
                        read SwitchIps
                        IFS=',' read -r -a SwitchIpArray <<< "$SwitchIps"
                        allValid=true
                        for ip in "${SwitchIpArray[@]}"; do
                            if ! [[ $ip =~ ^10\.252\.252\.[0-9]+$ ]]; then
                                echo -e "\033[31m ( 無效輸入，規則 10.252.252.X ) \033[0m "
                                allValid=false
                                break
                            fi
                        done
                        if $allValid; then
                            break
                        fi
                    done
                    # vxlan - vlan 填寫
                    echo -e $'\e[1;97;44m【 vLan ID - 填寫 】\e[0m '
                    while true; do
                        echo -n -e "\033[1;31m ❯ 填寫: \033[0m"
                        read vLanID
                        if [[ $vLanID =~ ^([1-9][0-9]{0,2}|[1-3][0-9]{3}|40[0-8][0-9]|409[0-4])$ ]]; then
                          #  vLanIdExists=false
                            for ip in "${SwitchIpArray[@]}"; do
                                vLanIdCheck=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${switchuser}@${ip} "show vlan brief | include $vLanID | awk '{print \$1}'" 2>/dev/null)
                                if [[ -z $vLanIdCheck ]]; then
                                #    vLanIdExists=true
                                    echo -e "\033[31m ( vLan ID ${vLanID} 在 ${ip} [不]存在，請重新輸入 ) \033[0m "
                                fi
                            done
                            break
                           # if ! $vLanIdExists; then
                           #     break
                           # fi
                        else
                            echo -e "\033[31m ( 無效輸入，規則 1-4096 ) \033[0m "
                        fi
                    done
                    #vxlan檢查
                    clear
                    echo "========================================================="
                    echo -e $'\e[1;97;44m【 移除 - 參數檢查 】\e[0m '
                    for ip in "${SwitchIpArray[@]}"; do
                        echo -e "\e[32m✔\e[0m Switch IP ➜ \e[1;31m ${ip}\e[0m"
                    done
                    echo -e "\e[32m✔\e[0m vLan ID ➜ \e[1;31m $vLanID\e[0m"
                    echo -e "\e[32m✔\e[0m vni member ➜ \e[1;31m 22$vLanID\e[0m"
                    echo "========================================================="
                    echo ""
                    echo -e $'\e[1;97;33m 檢查完成? 執行部署?  \e[0m '
                    echo "▶ Yes"
                    echo "▶ No"
                    while true; do
                        echo -n -e "\033[1;31m ❯ 填寫: \033[0m"
                        read confirm
                        if [ "${confirm,,}" = "yes" ]; then
                            break
                        elif [ "${confirm,,}" = "no" ]; then
                            break
                        else
                            echo -e "\033[31m ( 無效輸入，請輸入'Yes' 'No' ) \033[0m "
                        fi
                    done
                    break
                else
                    echo -e "\033[31m ( 無效輸入，請輸入 ) \033[0m "
                fi
                # vxlan - 數據收集完成
            done
            break

        ####### Other功能
        elif [ "${ChooseFunction,,}" = "cq" ]; then
            vCenterIP="10.31.2.10"
            break
        else
            echo -e "\033[31m ( 無效輸入，請輸入 ) \033[0m "
        fi
    done
}
login
#卡控是否部署
if [ "$confirm" == "yes" ]; then
    # vxlan部署
    if [ "${ChooseFunction,,}" = "vxlan" ]; then
        # add/del
        if [ "${ChooseVxLanStat,,}" = "add" ]; then
            for ip in "${SwitchIpArray[@]}"; do
                echo -e "\n"
                echo -n -e $'\e[1;97;42m【 在 '"$ip"' 開始部署 】\e[0m '
                echo -e "\n"
                LoopBackIp=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${switchuser}@${ip} "show running-config interface loopback 0 | begin 'ip address' | head -n 1 | sed 's/ip address //; s/\/.*//' | sed 's/^[[:space:]]*//'" 2>/dev/null)
                sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${switchuser}@${ip} <<EOF
configure terminal
vlan ${vLanID}
name ${NameRule}
vn-segment 22${vLanID}
end

configure terminal
interface nve1
member vni 22${vLanID}
ingress-replication protocol bpg
end

configure terminal
evpn
vni 22${vLanID} l2
rd ${LoopBackIp}:2${vLanID}
route-target import auto
route-target export auto
end
exit
EOF
                echo -n -e $'\e[1;97;42m【 在 '"$ip"' 完成部署 】\e[0m '
                echo -e "\n"
            done
        elif [ "${ChooseVxLanStat,,}" = "del" ]; then
            for ip in "${SwitchIpArray[@]}"; do
                echo -e "\n"
                echo -n -e $'\e[1;97;42m【 在 '"$ip"' 開始部署 】\e[0m '
                echo -e "\n"
                sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${switchuser}@${ip} <<EOF
configure terminal
no vlan ${vLanID} 
end

configure terminal
interface nve1
no member vni 22${vLanID}
end

configure terminal
evpn
no vni 22${vLanID} l2
EOF
                echo -n -e $'\e[1;97;42m【 在 '"$ip"' 完成部署 】\e[0m '
                echo -e "\n"
            done
        else
            echo ""
        fi

    else
        echo "還沒開發"
    fi
elif [ "$confirm" == "no" ];then
    echo -n -e $'\e[1;97;41m【 '${ChooseFunction}' 取消部署 】\e[0m '
    echo -e "\n"
else
    echo -e "\033[31m ( 無效輸入，請輸入'Yes' 'No' ) \033[0m "
fi
