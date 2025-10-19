---
date: '2016-08-18T09:54:55+08:00'
draft: false
title: 'Huffman编码压缩算法及其实现'
categories: ["0和1"]
tags: ["Huffman","压缩"]
---
哈弗曼编码是一个很经典的压缩算法，压缩率能达到50%，甚至更低。它的基本原理包括四个步骤：

1. 统计文件中每个字符出现的频率。
2. 构建一个哈弗曼树。建树的过程是不断的合并频率最小的两个节点，父亲节点的频率为两个孩子节点的频率之和。如此循环直到合并成一个根节点。叶子节点为不同的字符及其频率。
3. 生成哈弗曼编码。从树根开始对树进行编码，比如进入左孩子的边标记为0，进入右孩子的边标记为1，这里的0和1都是二进制位。这样之后，每个叶子节点都有一个唯一的二进制编码，这就是哈弗曼编码。频率越低的字符哈弗曼编码越长，频率越高的字符哈弗曼编码越短，这样就能起到压缩的效果。
4. 第二遍扫描文件，把字符转换为对应的哈弗曼编码，保存成压缩文件。

解压缩的过程就是解析二进制位，然后查找哈弗曼树，每找到一个叶子节点，就解析出一个字符，直到解析完所有二进制位。下面详细解释我的C++实现。

首先定义一个哈弗曼编码类，对外只提供压缩Compress和解压缩Decompress两个接口。值得注意的是有一个Node结构体，用于构成哈弗曼树的节点。此外count_node的key是字符频率，value是所在节点，且是multimap类型的，所以count_node会自动按字符频率有小到大排序，在构建哈弗曼树时，每次只需要取count_node的前两个节点进行合并即可。

```cpp
class HuffmanCode {

public:
    HuffmanCode();

    void Compress(string src, string dest);
    void Decompress(string src, string dest);

    virtual ~HuffmanCode();

private:
    void CountLetter(string src);
    void ConstructHuffmanTree();
    void GenerateHuffmanCode();
    void WriteHuffmanCode(ofstream &os);
    void Compressing(string src, string dest);

    void InsertIntoHuffmanTree(char letter, string &code, int &k);
    void ConstructHuffmanTreeFromFile(ifstream &is);
    void Decompressing(ifstream &is, ofstream &os);

    map<char, int> letter_count;
    typedef struct Node {
        int id;
        bool is_leaf;
        char letter;
        int parent, lchild, rchild;
        Node() {
        }
        Node(int i, bool il, char lt, int p, int lc, int rc) :
            id(i), is_leaf(il), letter(lt), parent(p), lchild(lc), rchild(rc) {
        }
    };
    multimap<int, Node> count_node;
    vector<Node> huffman_tree;
    map<char, vector<char>> letter_hcode; // hufman code for each letter
};
```

压缩函数Compress串起压缩的整个流程，包括统计字符频率、构建哈弗曼树、生成哈弗曼编码以及最后将原始文件转换成哈弗曼编码的二进制文件。

```cpp
void HuffmanCode::Compress(string src, string dest) {
    CountLetter(src);
    ConstructHuffmanTree();
    GenerateHuffmanCode();
    Compressing(src, dest);
}
```

Compress中的前三个函数不难，值得注意的是Compressing函数，它是真正进行压缩的函数。函数首先调用WriteHuffmanCode把每个字符的哈弗曼编码写入文件，作为文件头信息，以备后续解压使用。然后循环读取文件，把字符转换为哈弗曼二进制编码。每8 bit哈弗曼二进制位构成一个char byte，多个byte构成os_buf，当os_buf满时写入文件。

在最后边界位置，需要小心处理。因为可能所有二进制位并不刚好是8的整数倍，所以在压缩文件的末尾用 1 byte作为标记。如果flag为0x0，则所有二进制位刚好是8的整数倍，无需特别处理。如果flag为0x01，则还剩小于8个二进制位需要单独放在一个byte里面，所以还需要一个byte存储剩余多少个二进制位。假设最后3个bytes分别为x,y,z，则如果z==0x0，则x,y常规解析；如果z==0x01，则只解析x中的前y个bits。

```cpp
void HuffmanCode::Compressing(string src, string dest) {
    ifstream is(src, ios::binary);
    ofstream os(dest, ios::binary);

    WriteHuffmanCode(os);

    char *is_buf = new char[MAX_LEN], *os_buf = new char[MAX_LEN];
    list<char> tmp_hcode;
    int start_pos = 0, i, j, k, len, t;
    char c, flag = 0x0; // flag for the last byte
    list<char>::iterator it;
    while (is.peek() != EOF) {
        is.read(is_buf, MAX_LEN);
        len = is.gcount();
        for (i = 0; i < len; i++)
            tmp_hcode.insert(tmp_hcode.end(), letter_hcode[is_buf[i]].begin(), letter_hcode[is_buf[i]].end());
        k = tmp_hcode.size() / 8;
        t = 0;
        i = 0;
        it = tmp_hcode.begin();
        while (i < 8 * k) {
            c = 0x0;
            for (j = i; j <= i + 7; j++) {
                c = (*it == '1') ? (c | (1 << (i + 7 – j))) : c; // char -> bit
                it++;
            }
            os_buf[t++] = c;
            i += 8;
        }
        os.write(os_buf, t * sizeof(char));
        tmp_hcode.erase(tmp_hcode.begin(), it);
    }
    c = 0x0;
    i = 7;
    bool done = true;
    while (it != tmp_hcode.end()) {
        done = false;
        c = (*it == '1') ? (c | (1 << i)) : c; // left bits
        i–;
        it++;
    }
    if (!done) {
        os.write(&c, sizeof(char));
        c = 7 – i; // only c bits used in the last byte
        os.write(&c, sizeof(char));
        flag = 0x1; // the last byte is incomplete
    }
    os.write(&flag, sizeof(char));
    is.close();
    os.close();
    delete[] is_buf;
    delete[] os_buf;

}
```

函数Decompress串起解压缩的整个流程。首先调用ConstructHuffmanTreeFromFile读取压缩文件的头信息，也就是字符和哈弗曼编码的对应关系，然后构建哈弗曼树。同样Decompressing是实际的解压缩过程，它不断读取哈弗曼二进制位，然后从哈弗曼树根节点开始往下走，直到到达一个叶子节点，则解析出一个字符，如此循环，直到解析完所有二进制位。

```cpp
void HuffmanCode::Decompress(string src, string dest) {
    ifstream is(src, ios::binary);
    ofstream os(dest, ios::binary);
    ConstructHuffmanTreeFromFile(is);
    Decompressing(is, os);
    is.close();
    os.close();
}
```

完整项目可以查看我的[Github项目HZip](https://github.com/01joy/HZip)，Windows版可执行程序请[点此下载](https://github.com/01joy/HZip/raw/master/Release/HZip.exe)。

压缩命令为：

```PowerShell
HZip.exe -c original_file_path compressed_file_path
```

解压缩命令为：

```PowerShell
HZip.exe -x compressed_file_path decompressed_file_path
```

下面是一些测试结果。

//还没有统计好。。。

//看来还是7Z道高一尺。

我后面发现HZip甚至可以压缩/解压缩中文txt、pdf、图片、视频等（其实只要是ASCII编码的应该都可以吧？）。但是中文压缩效率较低，图片视频等压缩之后的大小几乎和没压缩是一样的:-(其实这很好理解，因为哈弗曼编码是根据字符频率的差异来编码的，英文只有26个字母加上一些符号，压缩效率肯定很高，而中文是以字为单位存储的，所以当以char读取来编码的时候，不同char的数量肯定更多，导致压缩效率较低。图片和视频就不得而知了。

在测试的时候我发现压缩和解压缩大文件的时候，速度极其的慢，简直到了不能忍的地步，下一步我将分析性能瓶颈，争取把速度提高到可以接受的范围。