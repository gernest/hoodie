pub const Head =
    \\ <!DOCTYPE html> 
    \\ <html> 
    \\  
    \\ <head> 
    \\     <meta http-equiv="Content-Type" content="text/html; charset=utf-8"> 
    \\     <meta name="viewport" content="width=device-width, initial-scale=1"> 
    \\     <title>{}</title>
    \\     <style> 
    \\         header { 
    \\             display: flex; 
    \\             flex-direction: row; 
    \\             flex-shrink: 0; 
    \\             width: 100%; 
    \\             padding: 0 100px; 
    \\             max-width: 1300px; 
    \\             align-items: center; 
    \\             margin: 0 auto; 
    \\             height: 75px 
    \\         } 
    \\  
    \\         header .nav { 
    \\             margin-left: 30px; 
    \\             font-size: 14px 
    \\         } 
    \\  
    \\         header .logo { 
    \\             display: flex 
    \\         } 
    \\  
    \\         header .logo img { 
    \\             width: 25px; 
    \\             height: 25px; 
    \\             margin-right: 20px 
    \\         } 
    \\  
    \\         @media (max-width:850px) { 
    \\             header .logo img { 
    \\                 width: 20px; 
    \\                 height: 20px; 
    \\                 margin-right: 10px 
    \\             } 
    \\  
    \\             header { 
    \\                 padding: 0 10% 
    \\             } 
    \\  
    \\             header .nav { 
    \\                 margin-left: 15px; 
    \\                 font-size: 14px 
    \\             } 
    \\         } 
    \\  
    \\         @media (max-width:350px) { 
    \\             header .logo img { 
    \\                 width: 20px; 
    \\                 height: 20px; 
    \\                 margin-right: 5px 
    \\             } 
    \\  
    \\             header { 
    \\                 padding: 0 10% 
    \\             } 
    \\  
    \\             header .nav { 
    \\                 margin-left: 10px; 
    \\                 font-size: 12px 
    \\             } 
    \\         } 
    \\  
    \\         footer { 
    \\             display: flex; 
    \\             flex-shrink: 0; 
    \\             align-items: center; 
    \\             max-width: 1300px; 
    \\             padding: 75px 100px; 
    \\             margin: 0 auto 
    \\         } 
    \\  
    \\         footer, 
    \\         footer .footer-inner { 
    \\             width: 100% 
    \\         } 
    \\  
    \\         footer .footer-inner .logo img { 
    \\             width: 25px; 
    \\             height: 25px; 
    \\             margin-right: 20px 
    \\         } 
    \\  
    \\         footer .footer-inner .footer-sections { 
    \\             display: flex; 
    \\             flex-direction: row 
    \\         } 
    \\  
    \\         footer .footer-inner .footer-sections .footer-links { 
    \\             display: flex; 
    \\             flex-direction: column; 
    \\             margin-top: 40px; 
    \\             min-width: 170px 
    \\         } 
    \\  
    \\         footer .footer-inner .footer-sections .footer-links>* { 
    \\             margin-bottom: 20px 
    \\         } 
    \\  
    \\         footer .footer-inner .footer-sections .footer-links:last-child { 
    \\             margin-bottom: 0 
    \\         } 
    \\  
    \\         footer .footer-inner .footer-sections .footer-links>h3 { 
    \\             font-size: 15px 
    \\         } 
    \\  
    \\         footer .footer-inner .footer-sections .footer-links>a { 
    \\             font-size: 14px 
    \\         } 
    \\  
    \\         @media (max-width:850px) { 
    \\             footer { 
    \\                 padding: 8.8% 10% 
    \\             } 
    \\  
    \\             footer .footer-inner .footer-sections .footer-links { 
    \\                 min-width: 120px 
    \\             } 
    \\         } 
    \\  
    \\         :root { 
    \\             --color-shadow: rgba(0, 0, 0, 0.15); 
    \\             --color-accent: #695fdf; 
    \\             --color-light: #f3f6f7; 
    \\             --color-medium: #d2d2d2; 
    \\             --color-dark: #2c3d51 
    \\         } 
    \\  
    \\         body, 
    \\         html { 
    \\             position: relative; 
    \\             height: 100% 
    \\         } 
    \\  
    \\         body { 
    \\             color: var(--color-dark); 
    \\             font-family: Open Sans, sans-serif; 
    \\             margin: 0; 
    \\             padding: 0 
    \\         } 
    \\  
    \\         body>div, 
    \\         body>div>div { 
    \\             height: 100% 
    \\         } 
    \\  
    \\         body>div, 
    \\         body>div>div, 
    \\         main { 
    \\             display: flex; 
    \\             flex-direction: column; 
    \\             position: relative 
    \\         } 
    \\  
    \\         main { 
    \\             flex-grow: 1; 
    \\             flex-shrink: 0 
    \\         } 
    \\  
    \\         * { 
    \\             box-sizing: border-box 
    \\         } 
    \\  
    \\         h1, 
    \\         h2, 
    \\         h3, 
    \\         h4 { 
    \\             font-family: Lato, sans-serif 
    \\         } 
    \\  
    \\         h1 { 
    \\             font-size: 2em; 
    \\             font-weight: 500; 
    \\             margin: 0 0 16px 
    \\         } 
    \\  
    \\         h2 { 
    \\             font-size: 1.5em 
    \\         } 
    \\  
    \\         h2, 
    \\         h3 { 
    \\             font-weight: 500; 
    \\             margin: 0 
    \\         } 
    \\  
    \\         h3, 
    \\         h4 { 
    \\             font-size: 1.2em 
    \\         } 
    \\  
    \\         h4 { 
    \\             font-weight: 400; 
    \\             margin: 0 
    \\         } 
    \\  
    \\         p { 
    \\             font-weight: 400; 
    \\             margin: 0 0 32px 
    \\         } 
    \\  
    \\         code, 
    \\         p { 
    \\             font-size: 1em; 
    \\             line-height: 1.5em 
    \\         } 
    \\  
    \\         code { 
    \\             font-family: Source Code Pro, monospace 
    \\         } 
    \\  
    \\         pre { 
    \\             background-color: #f9f9f9; 
    \\             border-radius: 4px; 
    \\             padding: 16px; 
    \\             margin: 32px 0 
    \\         } 
    \\  
    \\         span { 
    \\             font-weight: 400; 
    \\             line-height: 1.5em; 
    \\             margin: 0 
    \\         } 
    \\  
    \\         label { 
    \\             font-size: 12px; 
    \\             font-weight: 500; 
    \\             letter-spacing: 1px; 
    \\             text-transform: uppercase; 
    \\             margin: 0 
    \\         } 
    \\  
    \\         a { 
    \\             text-decoration: none; 
    \\             color: var(--color-dark) 
    \\         } 
    \\  
    \\         a:hover { 
    \\             cursor: pointer; 
    \\             opacity: .7 
    \\         } 
    \\  
    \\         button { 
    \\             font-size: 14px; 
    \\             font-weight: 500; 
    \\             display: block; 
    \\             width: 100%; 
    \\             border: none; 
    \\             background-color: transparent; 
    \\             margin: 0; 
    \\             padding: 0 
    \\         } 
    \\  
    \\         button:hover, 
    \\         input[type=submit]:hover { 
    \\             cursor: pointer; 
    \\             opacity: .7 
    \\         } 
    \\  
    \\         input, 
    \\         textarea { 
    \\             font-size: 1em; 
    \\             font-weight: 400; 
    \\             line-height: 1.5em; 
    \\             margin: 0; 
    \\             background-color: transparent; 
    \\             -webkit-appearance: none; 
    \\             -moz-appearance: none; 
    \\             appearance: none; 
    \\             box-sizing: border-box; 
    \\             font-family: Open Sans, sans-serif 
    \\         } 
    \\  
    \\         .spacer { 
    \\             flex: 1 1 
    \\         } 
    \\  
    \\         .section-inner { 
    \\             display: flex; 
    \\             flex-direction: column; 
    \\             width: 100%; 
    \\             align-items: stretch; 
    \\             max-width: 1300px; 
    \\             padding: 75px 100px; 
    \\             margin: 0 auto 
    \\         } 
    \\  
    \\         .section-inner>h2 { 
    \\             margin-bottom: 50px 
    \\         } 
    \\  
    \\         @media (max-width:850px) { 
    \\             section .section-inner { 
    \\                 padding: 8.8% 10%; 
    \\                 flex-direction: column 
    \\             } 
    \\  
    \\             .section-inner>h2 { 
    \\                 margin-top: 8%; 
    \\                 margin-bottom: 5% 
    \\             } 
    \\         } 
    \\  
    \\         section.hero-content>* { 
    \\             align-items: center 
    \\         } 
    \\  
    \\         .hero-content .title-letters { 
    \\             display: flex; 
    \\             flex-direction: row; 
    \\             max-width: 100% 
    \\         } 
    \\  
    \\         .hero-content .title-letter { 
    \\             margin-left: 10px; 
    \\             margin-right: 10px; 
    \\             height: 100px 
    \\         } 
    \\  
    \\         .hero-content p { 
    \\             margin-top: 20px; 
    \\             font-weight: 400; 
    \\             font-size: 21px; 
    \\             margin-bottom: 20px; 
    \\             text-align: center 
    \\         } 
    \\  
    \\         .hero-content .badges { 
    \\             display: flex; 
    \\             flex-wrap: wrap; 
    \\             justify-content: center; 
    \\             margin-bottom: 75px 
    \\         } 
    \\  
    \\         .hero-content .badges>* { 
    \\             margin-right: 10px 
    \\         } 
    \\  
    \\         .hero-content .badges:last-child { 
    \\             margin-right: 0 
    \\         } 
    \\  
    \\         .card-collection { 
    \\             display: flex; 
    \\             flex-direction: row; 
    \\             justify-content: space-around 
    \\         } 
    \\  
    \\         .card-collection>* { 
    \\             display: flex; 
    \\             flex-direction: row; 
    \\             margin-right: 10px; 
    \\             margin-left: 10px; 
    \\             max-width: 40%; 
    \\             flex: 1 1 
    \\         } 
    \\  
    \\         .card-collection:first-child { 
    \\             margin-left: 0 
    \\         } 
    \\  
    \\         .card-collection:last-child { 
    \\             margin-right: 0 
    \\         } 
    \\  
    \\         .card-collection .card { 
    \\             display: flex; 
    \\             flex-direction: column; 
    \\             background: #fff; 
    \\             color: var(--color-dark); 
    \\             box-shadow: 0 0 6px 0 var(--color-shadow); 
    \\             border-radius: 10px; 
    \\             padding: 25px; 
    \\             flex: 1 1 
    \\         } 
    \\  
    \\         .card-collection .card h3 { 
    \\             margin-bottom: 10px 
    \\         } 
    \\  
    \\         .card-collection .card span { 
    \\             font-size: 15px; 
    \\             line-height: 200% 
    \\         } 
    \\  
    \\         .card-collection .card span a { 
    \\             color: var(--color-accent) 
    \\         } 
    \\  
    \\         .button-group { 
    \\             display: flex; 
    \\             margin-top: 50px; 
    \\             text-align: center 
    \\         } 
    \\  
    \\         .button-group>* { 
    \\             margin-right: 20px 
    \\         } 
    \\  
    \\         .button-group:last-child { 
    \\             margin-right: 0 
    \\         } 
    \\  
    \\         .button-group .primary { 
    \\             background-color: var(--color-dark); 
    \\             color: #fff 
    \\         } 
    \\  
    \\         .button-group .primary, 
    \\         .button-group .secondary { 
    \\             font-size: 14px; 
    \\             border: 2px solid var(--color-dark); 
    \\             border-radius: 8px; 
    \\             font-weight: 700; 
    \\             width: auto; 
    \\             flex-shrink: 0; 
    \\             text-transform: uppercase; 
    \\             flex: 1 1; 
    \\             margin-left: 0; 
    \\             margin-top: 10px; 
    \\             padding: 15px 20px 
    \\         } 
    \\  
    \\         .button-group .secondary { 
    \\             background-color: clear; 
    \\             color: var(--color-dark) 
    \\         } 
    \\  
    \\         section.featured-projects { 
    \\             background-color: var(--color-light) 
    \\         } 
    \\  
    \\         section.blog-posts { 
    \\             background-color: #fff; 
    \\             background-color: var(--color-light) 
    \\         } 
    \\  
    \\         section.blog-posts>.section-inner { 
    \\             padding: 0 100px 75px 
    \\         } 
    \\  
    \\         section.cross-platform { 
    \\             background-color: var(--color-dark); 
    \\             color: #fff 
    \\         } 
    \\  
    \\         section.cross-platform>.section-inner { 
    \\             padding: 75px 100px 35px 
    \\         } 
    \\  
    \\         section.cross-platform .section-inner>h2 { 
    \\             margin-bottom: 10px 
    \\         } 
    \\  
    \\         .code-blocks { 
    \\             display: flex; 
    \\             flex-direction: row; 
    \\             justify-content: space-around; 
    \\             flex-wrap: wrap 
    \\         } 
    \\  
    \\         .code-blocks>* { 
    \\             display: flex; 
    \\             flex-direction: row; 
    \\             margin: 40px 20px; 
    \\             flex: 1 1; 
    \\             min-width: 40% 
    \\         } 
    \\  
    \\         .code-blocks:first-child { 
    \\             margin-left: 0 
    \\         } 
    \\  
    \\         .code-blocks:last-child { 
    \\             margin-right: 0 
    \\         } 
    \\  
    \\         .code-blocks .code-block { 
    \\             display: flex; 
    \\             flex-direction: column; 
    \\             background: #fff; 
    \\             color: var(--color-dark); 
    \\             box-shadow: 0 0 6px 0 var(--color-shadow); 
    \\             border-radius: 10px; 
    \\             overflow: hidden 
    \\         } 
    \\  
    \\         .code-blocks .code-block pre { 
    \\             margin: 10px; 
    \\             font-size: 14px 
    \\         } 
    \\  
    \\         .code-blocks .code-block>code { 
    \\             background-color: var(--color-light); 
    \\             padding: 10px 10px 10px 18px; 
    \\             font-size: 14px; 
    \\             font-weight: 700; 
    \\             border-bottom: 1px solid var(--color-medium) 
    \\         } 
    \\  
    \\         @media (max-width:850px) { 
    \\             section.blog-posts>.section-inner { 
    \\                 padding: 0 10% 8.8% 
    \\             } 
    \\  
    \\             section.cross-platform>.section-inner { 
    \\                 padding: 8.8% 10% 
    \\             } 
    \\  
    \\             .hero-content .title-letter { 
    \\                 margin-left: 5px; 
    \\                 margin-right: 5px; 
    \\                 height: 50px 
    \\             } 
    \\  
    \\             .hero-content p { 
    \\                 font-size: 16px 
    \\             } 
    \\  
    \\             .card-collection { 
    \\                 flex-direction: column; 
    \\                 align-items: stretch 
    \\             } 
    \\  
    \\             .card-collection>* { 
    \\                 margin: 20px 0; 
    \\                 max-width: 100% 
    \\             } 
    \\  
    \\             .card-collection:first-child { 
    \\                 margin-top: 0 
    \\             } 
    \\  
    \\             .card-collection:last-child { 
    \\                 margin-bottom: 0 
    \\             } 
    \\  
    \\             .button-group { 
    \\                 align-self: stretch; 
    \\                 margin-top: 25px; 
    \\                 flex-direction: column 
    \\             } 
    \\  
    \\             .button-group>* { 
    \\                 margin-right: 0; 
    \\                 margin-top: 20px 
    \\             } 
    \\  
    \\             .button-group:last-child { 
    \\                 margin-top: 0 
    \\             } 
    \\  
    \\             .code-blocks>* { 
    \\                 margin: 20px 0; 
    \\                 min-width: 100% 
    \\             } 
    \\  
    \\             .hero-content .badges { 
    \\                 margin-bottom: 8.8% 
    \\             } 
    \\         } 
    \\  
    \\         .doc-pills { 
    \\             display: flex; 
    \\             flex-wrap: wrap; 
    \\             flex-direction: row 
    \\         } 
    \\  
    \\         .doc-pill { 
    \\             margin-right: 10px; 
    \\             margin-bottom: 10px; 
    \\             padding: 8px 25px; 
    \\             background-color: #fff; 
    \\             border-radius: 8px; 
    \\             color: var(--color-dark); 
    \\             border: 1px solid var(--color-dark) 
    \\         } 
    \\  
    \\         .doc-pill.active:hover { 
    \\             opacity: 1 
    \\         } 
    \\  
    \\         .doc-pill.active { 
    \\             background-color: var(--color-dark); 
    \\             border: 1px solid var(--color-dark); 
    \\             color: #fff 
    \\         } 
    \\  
    \\         section.docs-header .section-inner { 
    \\             max-width: 1000px 
    \\         } 
    \\  
    \\         section.mdx-content .section-inner { 
    \\             padding: 0 100px 75px; 
    \\             max-width: 1000px 
    \\         } 
    \\  
    \\         section.docs-header p a, 
    \\         section.mdx-content p a { 
    \\             color: var(--color-accent) 
    \\         } 
    \\  
    \\         .mdx-content hr { 
    \\             border: 0; 
    \\             height: 1px; 
    \\             background: #ccc; 
    \\             margin-bottom: 40px 
    \\         } 
    \\  
    \\         .docs-header p, 
    \\         .mdx-content p { 
    \\             line-height: 180% 
    \\         } 
    \\  
    \\         .mdx-content p+ul { 
    \\             margin-top: -10px 
    \\         } 
    \\  
    \\         .mdx-content li { 
    \\             list-style: none; 
    \\             line-height: 180% 
    \\         } 
    \\  
    \\         .mdx-content li+li { 
    \\             margin-top: 10px 
    \\         } 
    \\  
    \\         .mdx-content li:before { 
    \\             content: "-"; 
    \\             margin-left: -20px; 
    \\             margin-right: 10px 
    \\         } 
    \\  
    \\         .mdx-content li code, 
    \\         .mdx-content p code { 
    \\             color: var(--color-accent) 
    \\         } 
    \\  
    \\         .mdx-content li code:after, 
    \\         .mdx-content li code:before, 
    \\         .mdx-content p code:after, 
    \\         .mdx-content p code:before { 
    \\             content: "`" 
    \\         } 
    \\  
    \\         .mdx-content .code-block { 
    \\             margin-bottom: 50px 
    \\         } 
    \\  
    \\         .mdx-content .code-block, 
    \\         .mdx-content .code-block .code-wrapper { 
    \\             display: flex; 
    \\             flex-direction: column; 
    \\             background-color: #292c33; 
    \\             color: var(--color-dark); 
    \\             box-shadow: 0 0 6px 0 var(--color-shadow); 
    \\             border-radius: 10px; 
    \\             overflow: hidden 
    \\         } 
    \\  
    \\         .mdx-content .code-block .code-wrapper { 
    \\             padding: 10px 
    \\         } 
    \\  
    \\         .mdx-content .code-block pre { 
    \\             margin: 0; 
    \\             border-radius: 0; 
    \\             font-size: 14px 
    \\         } 
    \\  
    \\         .mdx-content .code-block>code { 
    \\             background-color: #292c33; 
    \\             padding: 10px 10px 10px 18px; 
    \\             font-size: 14px; 
    \\             font-weight: 700; 
    \\             border-bottom: 1px solid #666; 
    \\             color: #fff 
    \\         } 
    \\  
    \\         @media (max-width:850px) { 
    \\             section.mdx-content>.section-inner { 
    \\                 padding: 0 10% 8.8% 
    \\             } 
    \\         } 
    \\     </style> 
    \\ </head> 
;
