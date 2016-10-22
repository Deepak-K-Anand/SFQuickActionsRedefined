.slds-card__body {
    background-color: #fff;
    border-top: 1px solid #d8dde6;
    height: 400px;
}

input[type=text],
select {
    width: 90%;
    height: 2.25rem;
    padding: 0.45rem;
    margin-top: 0.3rem !important;
    margin-right: 0.2rem !important;
    border: 1px solid #dcdcdc;
    border-radius: 5px;
    -moz-box-shadow: 0 2px 2px rgb(208,213,214) inset;
    -webkit-box-shadow: 0 2px 2px #dcdcdc inset;
    box-shadow: 0 2px 2px #dcdcdc inset;
}

input[type=checkbox] {
    position: relative;
    width: 1.5rem;
    height: 1.5rem;
    top: 0.5rem;
}

select {
    box-shadow: none;
    background-image: -moz-linear-gradient(top,rgb(255,255,255) 16%,rgb(243,243,243) 58% );
    background-image: -webkit-linear-gradient(top,#fff 16%,#f3f3f3 58% );
    background-image: -ms-linear-gradient(top,rgb(255,255,255) 16%,rgb(243,243,243) 58% );
    background-image: -webkit-gradient(linear,left top,left bottom,color-stop(.16,#fff ),color-stop(.58,#f3f3f3 ) );
    background-image: linear-gradient(top,rgb(255,255,255) 16%,rgb(243,243,243) 58% );
}

textarea {
    display: block;
    width: 90%;
    min-height: 85px;
    padding: 0.45rem;
    border: 1px solid #dcdcdc;
    border-radius: 5px;
    box-shadow: 0 0 5px #dcdcdc inset;
    resize: vertical;
}

input[type=text], 
textarea, 
select {
    -webkit-transition: all 0.30s ease-in-out;
    -moz-transition: all 0.30s ease-in-out;
    -ms-transition: all 0.30s ease-in-out;
    -o-transition: all 0.30s ease-in-out;
    transition: all 0.30s ease-in-out;
    border: 1px solid #DDDDDD;
}
 
input[type=text]:focus, 
textarea:focus, 
select:focus {
    outline: none;
    box-shadow: 0 0 5px #0a85f1;
    border: 1px solid #0a85f1;
}

.dateFormat {
    display: block;
}

.lookupInput {
    vertical-align: inherit;
    display: block;
}

.datePicker .dateBar select {
    width: inherit;
    height: inherit;
    padding: inherit;
    margin-top: inherit;
    margin-right: inherit;
}

.datePicker .dateBar select:focus {
    outline: none;
}

.n-ids-message {
    width: 90% !important; 
    min-height: 85px !important; 
    resize: none
}