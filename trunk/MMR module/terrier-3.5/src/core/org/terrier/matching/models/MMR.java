/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package org.terrier.matching.models;

import org.terrier.matching.ResultSet;

/**
 *
 * @author Pankaj
 */
public class MMR 

{
    
    
    int theta=50;
     int[] docid;
     int docid1;
    private int gettheta(ResultSet rs) {
        
        
       return 3;
    }
     public ResultSet getResultSet(ResultSet set1){
     
      ResultSet MMRSet=set1.getResultSet(0,1);
      return MMRSet;
     }
    
    
}
