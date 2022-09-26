# interweaving of code and output generates correct html

    ---
    output: hugodown::md_document
    rmd_hash: 51bc60383311007d
    
    ---
    
    ## Mixed as_is and coode
    
    <div class="highlight">
    
    <pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>df</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/data.frame.html'>data.frame</a></span><span class='o'>(</span>x <span class='o'>=</span> <span class='m'>1</span><span class='o'>)</span></span>
    <span><span class='nv'>df</span></span><span><span class='c'>#&gt;   x</span></span>
    <span><span class='c'>#&gt; 1 1</span></span><span></span>
    <span><span class='nf'>knitr</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/knitr/man/kable.html'>kable</a></span><span class='o'>(</span><span class='nv'>df</span><span class='o'>)</span></span></code></pre>
    
    |   x |
    |----:|
    |   1 |
    
    </div>
    
    ## All code/output
    
    <div class="highlight">
    
    <pre class='chroma'><code class='language-r' data-lang='r'><span><span class='c'># comment</span></span>
    <span><span class='nf'><a href='https://rdrr.io/r/base/print.html'>print</a></span><span class='o'>(</span><span class='s'>"print"</span><span class='o'>)</span></span><span><span class='c'>#&gt; [1] "print"</span></span><span><span class='nf'><a href='https://rdrr.io/r/base/message.html'>message</a></span><span class='o'>(</span><span class='s'>"message"</span><span class='o'>)</span></span><span><span class='c'>#&gt; message</span></span><span><span class='kr'><a href='https://rdrr.io/r/base/warning.html'>warning</a></span><span class='o'>(</span><span class='s'>"warning"</span><span class='o'>)</span></span><span><span class='c'>#&gt; Warning: warning</span></span></code></pre>
    
    </div>
    
    ## Chunk with only a figure
    
    <div class="highlight">
    
    <img src="figs/unnamed-chunk-3-1.png" width="700px" style="display: block; margin: auto;" />
    
    </div>
    

# curly operator is escaped

    <pre class='chroma'><code class='language-r' data-lang='r'><span><span class='o'>&#123;</span><span class='o'>&#123;</span> <span class='nv'>curly</span> <span class='o'>&#125;</span><span class='o'>&#125;</span></span></code></pre>

