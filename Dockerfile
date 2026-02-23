FROM alpine:latest

RUN apk update && apk add --no-cache \
    zsh \
    zsh-syntax-highlighting \
    git \

# zsh-abbr
RUN git clone --recurse-submodules https://github.com/olets/zsh-abbr /usr/share/zsh-abbr

# zsh
COPY zsh/.zshrc /root/.zshrc

SHELL ["/bin/zsh", "-c"]
CMD ["zsh"]
