/**
 * The reader's stylesheet, inlined into the generated page.
 *
 * The design brief: this is a formal definition of a board game, so the page reads as a bound
 * monograph rather than an API dump. Literata sets the prose, IBM Plex Mono sets every piece of
 * Lean, and the only ornament is a hairline rule system. Colour is carried by three signals and
 * nothing else — jade for definitions, amber for proofs, clay for keywords — so a glance at a
 * chapter tells you whether you are reading rules or reading evidence.
 *
 * The palette is defined once on `:root` and redefined for the dark preference and for the explicit
 * `data-theme` values, so the toggle wins in both directions.
 */
export const style = `
:root{
  color-scheme:light dark;
  --ground:#eef1eb;--plate:#f7f9f4;--raise:#ffffff;--rule:#d2dcd2;--rule-soft:#e2e9e0;
  --ink:#0f1a16;--quiet:#54655c;--jade:#0b6b51;--amber:#8a5a10;--clay:#a3432d;--sky:#1c5b8c;
  --shade:#e7ece4;
  --serif:'Literata',Iowan Old Style,Palatino,Georgia,serif;
  --mono:'IBM Plex Mono',SFMono-Regular,Menlo,Consolas,monospace;
}
@media (prefers-color-scheme:dark){
  :root:not([data-theme='light']){
    --ground:#0a1310;--plate:#0f1a16;--raise:#14211c;--rule:#22352d;--rule-soft:#1a2a24;
    --ink:#e8f1ea;--quiet:#8fa79d;--jade:#6fd6ae;--amber:#e2b25f;--clay:#ef9481;--sky:#8fc6f2;
    --shade:#0d1714;
  }
}
:root[data-theme='dark']{
  --ground:#0a1310;--plate:#0f1a16;--raise:#14211c;--rule:#22352d;--rule-soft:#1a2a24;
  --ink:#e8f1ea;--quiet:#8fa79d;--jade:#6fd6ae;--amber:#e2b25f;--clay:#ef9481;--sky:#8fc6f2;
  --shade:#0d1714;
}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
body{margin:0;background:var(--ground);color:var(--ink);font:400 16px/1.68 var(--serif);
  -webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility}
a{color:inherit}
h1,h2,h3,h4{font-weight:600;line-height:1.15;letter-spacing:-0.015em;margin:0}
code,pre,.mono{font-family:var(--mono);font-variant-ligatures:none}
.skip{position:absolute;left:-9999px;top:0;padding:10px 14px;background:var(--raise);z-index:9}
.skip:focus{left:8px;top:8px}
:focus-visible{outline:2px solid var(--jade);outline-offset:3px;border-radius:2px}

.shell{display:grid;grid-template-columns:16rem minmax(0,1fr);gap:0;max-width:84rem;margin:0 auto}
.spine{position:sticky;top:0;align-self:start;height:100vh;display:flex;flex-direction:column;
  gap:14px;padding:26px 20px 20px;border-right:1px solid var(--rule)}
.mark{display:block;font-size:22px;font-weight:600;letter-spacing:-0.03em;text-decoration:none}
.mark span{color:var(--jade)}
.spine-note{margin:0;color:var(--quiet);font-size:13px;line-height:1.4}
.find{display:flex;gap:6px}
.find input{flex:1;min-width:0;padding:8px 10px;border:1px solid var(--rule);border-radius:2px;
  background:var(--raise);color:var(--ink);font:400 13px/1.4 var(--mono)}
.find input::placeholder{color:var(--quiet)}
.tocwrap{flex:1;overflow:auto;margin-right:-8px;padding-right:8px}
.toc-part{margin:0 0 14px}
.toc-part[hidden]{display:none}
.toc-part>p{margin:0 0 4px;font-size:12px;font-weight:600;color:var(--quiet);letter-spacing:0.01em}
.toc-part ul{margin:0;padding:0;list-style:none}
.toc-part a{display:block;padding:2px 0 2px 10px;border-left:1px solid var(--rule-soft);
  color:var(--quiet);font:400 13px/1.5 var(--mono);text-decoration:none;overflow:hidden;
  text-overflow:ellipsis;white-space:nowrap}
.toc-part a:hover,.toc-part a:focus-visible{color:var(--ink);border-left-color:var(--jade)}
.toc-part a[hidden]{display:none}
.spine-foot{display:flex;align-items:center;justify-content:space-between;gap:8px;
  border-top:1px solid var(--rule);padding-top:12px;color:var(--quiet);font-size:12px}
button{font:inherit;color:inherit;cursor:pointer}
.ghost{border:1px solid var(--rule);border-radius:2px;background:none;padding:5px 9px;
  font:400 12px/1 var(--mono);color:var(--quiet)}
.ghost:hover{color:var(--ink);border-color:var(--jade)}

main{min-width:0;padding:0 clamp(18px,4vw,58px) 96px}
.hero{padding:clamp(48px,9vw,104px) 0 40px;max-width:46rem}
.hero p.kicker{margin:0 0 18px;color:var(--quiet);font-size:15px}
.hero h1{font-size:clamp(2.3rem,6.4vw,4rem);letter-spacing:-0.035em}
.hero-sig{margin:28px 0 0;padding:18px 20px;border:1px solid var(--rule);border-left:3px solid var(--jade);
  border-radius:2px;background:var(--plate);overflow-x:auto;font-size:15px;line-height:1.6}
.lede{margin:26px 0 0;font-size:1.06rem;color:var(--ink);max-width:38rem}
.lede + .lede{margin-top:14px}
.tally{display:flex;flex-wrap:wrap;gap:26px;margin:34px 0 0;padding:18px 0 0;
  border-top:1px solid var(--rule)}
.tally div{min-width:5rem}
.tally dt{margin:0;color:var(--quiet);font-size:12.5px}
.tally dd{margin:2px 0 0;font-size:24px;font-weight:600;letter-spacing:-0.02em;font-variant-numeric:tabular-nums}

.guide{max-width:52rem;margin:56px 0 0;padding:30px 0 0;border-top:1px solid var(--rule)}
.guide h2{font-size:1.5rem}
.guide>p{max-width:38rem;color:var(--quiet)}
.route{counter-reset:route;margin:26px 0 0;padding:0;list-style:none}
.route li{counter-increment:route;display:grid;grid-template-columns:2.4rem minmax(0,1fr);gap:16px;
  padding:14px 0;border-top:1px solid var(--rule-soft)}
.route li::before{content:counter(route,decimal-leading-zero);color:var(--jade);
  font:400 13px/1.7 var(--mono)}
.route a{font-size:1.05rem;font-weight:600;text-decoration:none;border-bottom:1px solid var(--rule)}
.route a:hover{border-bottom-color:var(--jade)}
.route p{margin:3px 0 0;color:var(--quiet);font-size:14.5px;max-width:34rem}

.chapter{max-width:56rem;margin:0;padding:62px 0 0;scroll-margin-top:14px}
.chapter[hidden]{display:none}
.plate{display:grid;grid-template-columns:2.6rem minmax(0,1fr);gap:16px;padding-bottom:20px;
  border-bottom:1px solid var(--rule)}
.plate .num{color:var(--jade);font:400 13px/1.9 var(--mono)}
.plate h2{font-size:clamp(1.55rem,3.4vw,2.05rem)}
.plate .where{margin:8px 0 0;color:var(--quiet);font:400 12.5px/1.6 var(--mono)}
.where a{text-decoration:none;border-bottom:1px solid var(--rule)}
.plate .builds{margin:8px 0 0;color:var(--quiet);font-size:13px;line-height:1.7}
.builds a{color:var(--quiet);text-decoration:none;border-bottom:1px solid var(--rule-soft);
  font-family:var(--mono);font-size:12px}
.builds a:hover{color:var(--ink)}

.prose{max-width:38rem;padding:22px 0 4px}
.prose h3{margin:28px 0 8px;font-size:1.18rem}
.prose h4{margin:22px 0 6px;font-size:1.02rem;color:var(--quiet)}
.prose p{margin:0 0 14px}
.prose ul,.prose ol{margin:0 0 14px;padding-left:1.2rem}
.prose li{margin:0 0 6px}
.prose code{font-size:0.86em;padding:1px 4px;border-radius:2px;background:var(--shade);color:var(--jade)}
.xref code{color:var(--jade);border-bottom:1px solid currentColor}
.prose blockquote{margin:0 0 16px;padding:2px 0 2px 16px;border-left:2px solid var(--amber);
  color:var(--quiet);font-style:italic}
.prose table{border-collapse:collapse;font-size:14px;min-width:100%}
.prose th,.prose td{padding:7px 14px 7px 0;text-align:left;vertical-align:top;
  border-bottom:1px solid var(--rule-soft)}
.prose th{color:var(--quiet);font-weight:600}
.scroller{overflow-x:auto;margin:0 0 18px;max-width:100%}

.band{display:flex;align-items:baseline;gap:12px;margin:34px 0 14px}
.band h3{font-size:1.02rem}
.band span{color:var(--quiet);font:400 12px/1 var(--mono)}
.band::after{content:'';flex:1;height:1px;background:var(--rule-soft)}

.decl{border:1px solid var(--rule);border-left:2px solid var(--jade);border-radius:2px;
  background:var(--plate);margin:0 0 10px;padding:14px 16px;scroll-margin-top:14px}
.decl[hidden]{display:none}
.decl.is-theorem{border-left-color:var(--amber)}
.decl:target{background:var(--raise);border-color:var(--jade)}
.decl-head{display:flex;flex-wrap:wrap;align-items:baseline;gap:10px}
.decl-head h4{font:600 15px/1.4 var(--mono);letter-spacing:0}
.decl-head h4 a{text-decoration:none}
.decl-head h4 a:hover{color:var(--jade)}
.decl-head .kind{color:var(--jade);font:400 11.5px/1 var(--mono)}
.decl.is-theorem .decl-head .kind{color:var(--amber)}
.decl-head .at{margin-left:auto;color:var(--quiet);font:400 11.5px/1 var(--mono)}
.sig{margin:10px 0 0;padding:0;overflow-x:auto;font-size:13px;line-height:1.62;color:var(--ink)}
.blurb{margin:10px 0 0;font-size:14.6px;max-width:38rem;color:var(--ink)}
.blurb p{margin:0 0 10px}
.blurb p:last-child{margin-bottom:0}
.blurb code{font-size:0.86em;color:var(--jade)}
.blurb ul,.blurb ol{margin:0 0 10px;padding-left:1.1rem}

.rests{display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin:12px 0 0;
  color:var(--quiet);font-size:12.5px}
.axiom{padding:2px 7px;border:1px solid var(--rule);border-radius:999px;
  font:400 11.5px/1.5 var(--mono);color:var(--quiet)}
.axiom.warn{border-color:var(--clay);color:var(--clay)}
.rests.warn{color:var(--clay)}

details{margin:12px 0 0}
details>summary{list-style:none;cursor:pointer;color:var(--quiet);font:400 12px/1.6 var(--mono);
  display:inline-flex;align-items:center;gap:7px}
details>summary::-webkit-details-marker{display:none}
details>summary::before{content:'+';display:inline-block;width:9px;color:var(--jade)}
details[open]>summary::before{content:'\\2212'}
details>summary:hover{color:var(--ink)}
pre.code{margin:10px 0 0;padding:14px 16px;border:1px solid var(--rule-soft);border-radius:2px;
  background:var(--shade);overflow-x:auto;font-size:12.8px;line-height:1.62;tab-size:2}
pre.plain{margin:10px 0 0;padding:14px 16px;border:1px dashed var(--rule);border-radius:2px;
  overflow-x:auto;font-size:12.5px;line-height:1.6;color:var(--quiet);white-space:pre-wrap}

pre b,pre i{font-style:normal;font-weight:400}
pre .k{color:var(--clay)}
pre .l,pre .n{color:var(--sky)}
pre .s{color:var(--amber)}
pre .c{color:var(--quiet);font-style:italic}
pre .o{color:var(--jade)}
pre a.r{color:inherit;text-decoration:none;border-bottom:1px dotted var(--rule)}
pre a.r:hover{color:var(--jade);border-bottom-color:var(--jade)}

.nothing{max-width:38rem;margin:60px 0;color:var(--quiet)}
.nothing[hidden]{display:none}
footer{max-width:56rem;margin:80px 0 0;padding:24px 0 0;border-top:1px solid var(--rule);
  color:var(--quiet);font-size:13.5px}

@media (max-width:900px){
  .shell{display:block}
  .spine{position:static;height:auto;flex-direction:column;border-right:0;
    border-bottom:1px solid var(--rule);padding:18px 16px}
  .tocwrap{max-height:44vh;overflow:auto}
  main{padding:0 16px 72px}
  .plate{grid-template-columns:minmax(0,1fr)}
  .plate .num{display:none}
  .route li{grid-template-columns:1.9rem minmax(0,1fr);gap:10px}
}
`
