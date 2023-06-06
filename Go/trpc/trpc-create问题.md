```
trpc create --protofile customer.proto -o stub/git.woa.com/trpcprotocol/tcc/tcc_main_customer --rpconly
Execution err:
 generate rpc stub from template inside create rpc stub err: generate pb fb: run protoc err: run protoc-gen-secv err: run command: `protoc --proto_path=/Users/houjichao/Work/Go/tencent/tcc/tcc_main --proto_path=/Users/houjichao/.trpc/submodules/trpc --proto_path=/Users/houjichao/.trpc/submodules --proto_path=/Users/houjichao/.trpc/protos/trpc --proto_path=/Users/houjichao/.trpc/protos --proto_path=/Users/houjichao/.trpc/protobuf --secv_out=lang=go,paths=source_relative,Mtcc/tcc_main/common.proto=git.woa.com/trpcprotocol/tcc/tcc_main_common,Mcustomer.proto=git.woa.com/trpcprotocol/tcc/tcc_main_customer,Mtrpc/common/validate.proto=git.code.oa.com/devsec/protoc-gen-secv/validate:/Users/houjichao/Work/Go/tencent/tcc/tcc_main/stub/git.woa.com/trpcprotocol/tcc/tcc_main_customer/tmp-1686059336712859000/stub/git.woa.com/trpcprotocol/tcc/tcc_main_customer customer.proto`, error: customer.proto:24:1: warning: Import trpc/common/validate.proto is unused.
customer.proto: is a proto3 file that contains optional fields, but code generator protoc-gen-secv hasn't been updated to support optional fields in proto3. Please ask the owner of this code generator to support proto3 optional.--secv_out: 
```

安装最新的secv版本

```
go install git.code.xx.com/devsec/protoc-gen-secv@latest
```

