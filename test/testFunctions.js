module.exports = {

    showLoanTokens: function(tokens, title) {

        let t0 = '';
        let t1 = '';
        let t2 = '';
        
        for (let i = 0; i < tokens[0].length;i++) {
            t0 = t0 + ' ' + BN(tokens[0][i]).toNumber();
        }
        for (let i = 0; i < tokens[1].length;i++) {
            t1 = t1 + ' ' + BN(tokens[1][i]).toNumber();
        }
        for (let i = 0; i < tokens[2].length;i++) {
            t2 = t2 + ' ' + BN(tokens[2][i]).toNumber();
        }
    
        var t = [{'Not Approved Tokens' : t0,
                'Approved Tokens' : t1, 
                'Declined Tokens' : t2}
                ];

        console.log('');
        console.log(`     ****** ${title} ******`);
        console.table(t);
    }
}
