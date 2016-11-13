# dotfiles
zsh、git、spacemacs、vim、pip以及一些scripts。

# 初始化
```shell
./setup.sh
```

# 一些说明
选用`ln`的方式安装，避免维护多份copy。

其实思考dotfiles里个人信息部分不被同步到git库，又不损失其可同步性上有过些纠结，最终选择的方案为：

**使用`git add --patch`的方式部分提交，避开个人信息部分。**

# TODO
- OSX - brew、ubuntu - apt

