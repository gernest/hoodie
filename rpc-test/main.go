package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"time"

	"github.com/gernest/hoodie/jsonrpc2"
)

type Request struct {
	// VersionTag is always encoded as the string "2.0"
	VersionTag string `json:"jsonrpc"`
	// Method is a string containing the method name to invoke.
	Method string `json:"method"`
	// Params is either a struct or an array with the parameters of the method.
	Params interface{} `json:"params,omitempty"`
	// The id of this request, used to tie the Response back to the request.
	// Will be either a string or a number. If not set, the Request is a notify,
	// and no response is possible.
	ID int `json:"id,omitempty"`
}

func main() {
	flag.Parse()
	a := flag.Args()
	switch len(a) {
	case 0:
	case 1:
		err := proxyCmd(context.Background(), a[0])
		if err != nil {
			log.Fatal(err)
		}
	default:
		err := proxyCmd(context.Background(), a[0], a[1:]...)
		if err != nil {
			log.Fatal(err)
		}
	}
}

func proxyCmd(ctx context.Context, name string, args ...string) error {
	cmdCtx, cancel := context.WithCancel(ctx)
	defer cancel()
	cmd := exec.CommandContext(cmdCtx, name, args...)
	stdin, err := cmd.StdinPipe()
	if err != nil {
		return err
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return err
	}
	err = cmd.Start()
	if err != nil {
		return err
	}
	go func() {
		io.Copy(os.Stderr, stderr)
	}()

	stream := jsonrpc2.NewHeaderStream(stdout, stdin)
	go handle(ctx, stream)
	return cmd.Wait()
}

func handle(ctx context.Context, stream jsonrpc2.Stream) error {
	conn := jsonrpc2.NewConn(stream)
	ticker := time.NewTicker(2 * time.Millisecond)
	defer ticker.Stop()
	id := 0
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			var result json.RawMessage
			fmt.Fprintf(os.Stdout, "echo :%v\n", id)
			err := conn.Call(ctx, "echo", []int{id}, &result)
			if err != nil {
				fmt.Fprintf(os.Stdout, "Error :%v\n", err)
			} else {
				fmt.Fprintf(os.Stdout, "=> %d: %s\n", id, string(result))
			}
			id++
		}
	}
}
