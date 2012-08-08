/*
 * Terrier - Terabyte Retriever
 * Webpage: http://terrier.org
 * Contact: terrier{a.}dcs.gla.ac.uk
 * University of Glasgow - School of Computing Science
 * http://www.ac.gla.uk
 *
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
 * the License for the specific language governing rights and limitations
 * under the License.
 *
 * The Original Code is InteractiveQuerying.java.
 *
 * The Original Code is Copyright (C) 2004-2011 the University of Glasgow.
 * All Rights Reserved.
 *
 * Contributor(s):
 *   Gianni Amati <gba{a.}fub.it> (original author)
 *   Vassilis Plachouras <vassilis{a.}dcs.gla.ac.uk>
 *   Ben He <ben{a.}dcs.gla.ac.uk>
 *   Craig Macdonald <craigm{a.}dcs.gla.ac.uk>
 */
package org.terrier.applications;
import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import org.terrier.matching.ResultSet;
import org.terrier.querying.Manager;
import org.terrier.querying.SearchRequest;
import org.terrier.structures.Index;
import org.terrier.structures.MetaIndex;
import org.terrier.utility.ApplicationSetup;

/**
 * This class performs interactive querying at the command line. It asks
 * for a query on Standard Input, and then displays the document IDs that
 * match the given query.
 * <p><b>Properties:</b>
 * <ul><li><tt>interactive.model</tt> - which weighting model to use, defaults to PL2</li>
 * <li><tt>interactive.matching</tt> - which Matching class to use, defaults to Matching</li>
 * <li><tt>interactive.manager</tt> - which Manager class to use, defaults to Matching</li>
 * </ul>
 * @author Gianni Amati, Vassilis Plachouras, Ben He, Craig Macdonald
 */
public class SentenceRetreivalNew {
	
   
    
    /** The logger used */
	protected static final Logger logger = Logger.getLogger(SentenceRetreivalNew.class);
	
	/** Change to lowercase? */
	protected final static boolean lowercase = Boolean.parseBoolean(ApplicationSetup.getProperty("lowercase", "true"));
	/** display user prompts */
	protected boolean verbose = true;
	/** the number of processed queries. */
	protected int matchingCount = 0;
	/** The file to store the output to.*/
	protected PrintWriter resultFile = new PrintWriter(System.out);
	/** The name of the manager object that handles the queries. Set by property <tt>trec.manager</tt>, defaults to Manager. */
	protected String managerName = ApplicationSetup.getProperty("interactive.manager", "Manager");
	/** The query manager.*/
	protected Manager queryingManager;
	/** The weighting model used. */
	protected String wModel = ApplicationSetup.getProperty("interactive.model", "BM25");
	/** The matching model used.*/
	protected String mModel = ApplicationSetup.getProperty("interactive.matching", "Matching");
	/** The data structures used.*/
	protected Index index;
	/** The maximum number of presented results. */
	protected static int RESULTS_LENGTH = 
		Integer.parseInt(ApplicationSetup.getProperty("interactive.output.format.length", "1000"));
	
	protected String[] metaKeys = ApplicationSetup.getProperty("interactive.output.meta.keys", "docno").split("\\s*,\\s*");
    
  
  
	
	/** A default constructor initialises the index, and the Manager. */
	public SentenceRetreivalNew() {
		loadIndex();
		createManager();		
	}

	/**
	* Create a querying manager. This method should be overriden if
	* another matching model is required.
	*/
	protected void createManager(){
		try{
		if (managerName.indexOf('.') == -1)
			managerName = "org.terrier.querying."+managerName;
		else if (managerName.startsWith("uk.ac.gla.terrier"))
			managerName = managerName.replaceAll("uk.ac.gla.terrier", "org.terrier");
		queryingManager = (Manager) (Class.forName(managerName)
			.getConstructor(new Class[]{Index.class})
			.newInstance(new Object[]{index}));
		} catch (Exception e) {
		//	logger.error("Problem loading Manager ("+managerName+"): ",e);	
		}
	}
	
	/**
	* Loads index(s) from disk.
	*
	*/
	protected void loadIndex(){
		long startLoading = System.currentTimeMillis();
		index = Index.createIndex();
		if(index == null)
		{
		//	logger.fatal("Failed to load index. Perhaps index files are missing");
		}
		long endLoading = System.currentTimeMillis();
		//if (logger.isInfoEnabled())
                {}
		//	//logger.info("time to intialise index : " + ((endLoading-startLoading)/1000.0D));
	}
	/**
	 * Closes the used structures.
	 */
	public void close() {
		try{
			index.close();
		} catch (IOException ioe) {
		//	//logger.warn("Problem closing index", ioe);
		}
		
	}
	/**
	 * According to the given parameters, it sets up the correct matching class.
	 * @param queryId String the query identifier to use.
	 * @param query String the query to process.
	 * @param cParameter double the value of the parameter to use.
	 */
	public void processQuery(String queryId, String query, double cParameter) {
		SearchRequest srq = queryingManager.newSearchRequest(queryId, query);
		srq.setControl("c", Double.toString(cParameter));
		srq.addMatchingModel(mModel, wModel);
		matchingCount++;
		queryingManager.runPreProcessing(srq);
		queryingManager.runMatching(srq);
		queryingManager.runPostProcessing(srq);
		queryingManager.runPostFilters(srq);
		try{
			printResults(resultFile, srq);
		} catch (IOException ioe) {
		//	logger.error("Problem displaying results", ioe);
		}
	}
	/**
	 * Performs the matching using the specified weighting model 
	 * from the setup and possibly a combination of evidence mechanism.
	 * It parses the file with the queries (the name of the file is defined
	 * in the address_query file), creates the file of results, and for each
	 * query, gets the relevant documents, scores them, and outputs the results
	 * to the result file.
	 * @param cParameter the value of c
	 */
	public void processQueries(double cParameter) {
		try {
			//prepare console input
			InputStreamReader consoleReader = new InputStreamReader(System.in);
			BufferedReader consoleInput = new BufferedReader(consoleReader);
			String query; int qid=1;
			if (verbose)
				System.out.print("Please enter your query: ");
			while ((query = consoleInput.readLine()) != null) {
				if (query.length() == 0 || 
					query.toLowerCase().equals("quit") ||
					query.toLowerCase().equals("exit")
				)
				{
					return;
				}
				processQuery(""+(qid++), lowercase ? query.toLowerCase() : query, cParameter);
				if (verbose)
					System.out.print("Please enter your query: ");
			}
		} catch(IOException ioe) {
		//	logger.error("Input/Output exception while performing the matching. Stack trace follows.",ioe);
		}
	}
	/**
	 * Prints the results
	 * @param pw PrintWriter the file to write the results to.
	 * @param q SearchRequest the search request to get results from.
	 */
     
        public void firstRSGenerator()throws IOException{
           /*
            * reading content of first document
            */
            try{
              meta1=index.getMetaIndex();  
              name=meta1.getItems("filename", docids);
              FileReader fr=new FileReader(name[0]);
              BufferedReader read=new BufferedReader(fr);
              while((str456=read.readLine())!=null)
              {
              //    System.out.println("str456 = "+str456);
                  firstdocument+=str456;    
                  str456=null;
             
              }
          
              /*
             * generating resultset using 1st document as a query
             */
              tempRS=obj1.main1(args1, firstdocument);
            //  System.out.println("received resultset using 1st document as a query : "+tempRS);
           /*
            * adding the above resultset to ResultSetHolder class object
            * 
            */
              rsh.add(new RSHolder());
              rsh.get(0).set=tempRS;
              rsh.get(0).content=firstdocument;
              rsh.get(0).qid=docids[0];
          //    System.out.println("the first object of Resultset holder class is : "+rsh.get(0));
               /*
                * putting the resultSetHolder class object in hashMap
                * 
                */
              hp.put(docids[0],rsh.get(0));
              
              fpointer++;
            //  System.out.println(" first object in hp : "+hp.get(docids[0]));
           //   System.out.println("control being passed to nextRSGenerator");
              nextRSGenerator();
          }
            catch(Exception e){
                //System.out.println("Sorry we cannot answer your query");
                
                   }
            }
     
        ArrayList<RSHolder> rsh=new ArrayList<RSHolder>();
        static HashMap<Integer,RSHolder> hp=new HashMap();
        static MetaIndex meta1;
        ResultSet tempRS;
        Sim1 obj1=new Sim1();
        int count=5;
        double tempscore=0.0;
        boolean flag=false;
        int n=0,p=0;
        RSHolder nextRSholder;
        ResultSet nextRS;
        int infinity=9999;
        double[] nextscores=new double[1000];
        int[] nextdocids;
        ResultSet set;  //set is the Parent Result Set
        int pointerOnParRS;
        int[] docids=new int[10000];
        static String name[];  //this contains path or address of all results of Parent RS.
        String firstdocument;
        String str123,str456,str789;
        static String args1[];
        static int fpointer=0;  
        private ResultSet receivedSet[];
        static String document;
        double[] scores;
        static int z=0;
        int maxcount=0;
        static int indexval;
        public void nextRSGenerator()throws FileNotFoundException,IOException{
        try{
            for(int j=1;j<count;j++){
            /*
             * reading the next document from the resultset
             */
                
              FileReader fr=new FileReader(name[j]);
              BufferedReader read=new BufferedReader(fr);
              while(( str123=read.readLine())!=null)
              {
            //      System.out.println("str123 = "+str123);
              document+=str123;     
              str123=null;
              }
                
           //     catch(Exception e)
             //   {
              //      System.out.println("Sorry we cannot answer your query");
              //  }
              /*
               * now, in object of resultSetHolder class 
               * next object is being added
               */
             
              rsh.add(new RSHolder());
              tempRS=obj1.main1(args1, document);
              rsh.get(j).set=tempRS;
              rsh.get(j).content=document;
              rsh.get(j).qid=docids[j];
              
              //tempscore contains the first value of score to be passsed to compare fn
              tempscore=scores[j];
             
            
              while(!hp.isEmpty()&&z<=7)
              {
                  if(hp.containsKey(docids[n]))   //n here statrts from 0 
                                                    //and this is if is to check whether that 
                                                    //particular docid pos is contained in hashmap
                  {
                   //    System.out.println("n= "+n);
                      nextRSholder=hp.get(docids[n]);
                  //    System.out.println("the object retreived from hp : "+nextRSholder);
                      /*
                       * retreiving the contents of the hp's object
                       * 
                       */
                      nextRS=nextRSholder.set;      //retreiving resultset
                 //  System.out.println("nextRS is : "+nextRS);
                      nextscores=nextRS.getScores();    //retreiving scores from the above rseultset
                //     System.out.println("nextscores array is : "+nextscores);
                      nextdocids=nextRS.getDocids();    //retreiving docids from the above rseultset
                //     System.out.println("nextdoicds is : "+nextdocids);
                      maxcount=nextdocids.length;
                   //     System.out.println("maxcount is : "+maxcount );
                        for(int p=0;p<maxcount;p++)
                        {
                           if(docids[j]==nextdocids[p])
                               indexval=p;
                        }
                      //  System.out.println("lenght of nextscores is : "+nextscores.length);
                      //  System.out.println("indexval value is "+indexval);
                      tempscore2[z]=nextscores[indexval];
                       z++;
                 }
              }
             if(compare(tempscore,max(tempscore2)))
                          hp.put(docids[n], rsh.get(j));
                  //        System.out.println("member added in hp : "+hp.get(docids[n]));
                      n++;
            }
        
        
                       

        } catch(Exception e)
            {
       //     System.out.println("Sorry,query cannot be proceesed");
            }
         printer();
        }
        static double lambda=0.0;
        double res;
        double[] tempscore2=new double[100];
        public boolean compare(double sim1val,double sim2val){
        
            res=(lambda*sim1val)-((1-lambda)*sim2val);
            if(res>=0)
                return true;
            else
                return false;
        }
         private double max(double[] nextscores) {
            double max;
            int length=nextscores.length;
            max=nextscores[0];
            for(int k=1;k<length;k++)
            {
                if(max<nextscores[k])  
                    max=nextscores[k];
             }
        return max;
    }
      //  public void sim1func(String doc){
        
        //    obj.main1(args1, doc);
       // }
        
	public void printResults(PrintWriter pw, SearchRequest q) throws IOException {
		set = q.getResultSet();
             
                
		docids = set.getDocids();
		scores = set.getScores();
                   firstRSGenerator();
		int minimum = RESULTS_LENGTH;
           
		//if the minimum number of documents is more than the
		//number of documents in the results, aw.length, then
		//set minimum = aw.length
		if (minimum > set.getResultSize())
			minimum = set.getResultSize();
	//	if (verbose)
	//		if(set.getResultSize()>0)
	//			pw.write("\n\tDisplaying 1-"+set.getResultSize()+ " results\n");
	//		else
	//			pw.write("\n\tNo results\n");
	//	if (set.getResultSize() == 0)
	//		return;
		
		int metaKeyId = 0; final int metaKeyCount = metaKeys.length;
		String[][] docNames = new String[metaKeyCount][];
		for(String metaIndexDocumentKey : metaKeys)
		{
			if (set.hasMetaItems(metaIndexDocumentKey))
			{
				docNames[metaKeyId] = set.getMetaItems(metaIndexDocumentKey);
			}
			else
			{
				final MetaIndex metaIndex = index.getMetaIndex();
				docNames[metaKeyId] = metaIndex.getItems(metaIndexDocumentKey, docids);
			}
			metaKeyId++;
		}
		
		
		StringBuilder sbuffer = new StringBuilder();
		//the results are ordered in asceding order
		//with respect to the score. For example, the
		//document with the highest score has score
		//score[scores.length-1] and its docid is
		//docid[docids.length-1].
		int start = 0;
		int end = minimum;
        }
	//	for (int i = start; i < end; i++) {
	//		sbuffer.append(i);
	//		sbuffer.append(" ");
	//		//sbuffer.append(docids[i]);
	//		for(metaKeyId = 0; metaKeyId < metaKeyCount; metaKeyId++)
	//		{
	//			sbuffer.append(docNames[metaKeyId][i]);
	//			sbuffer.append(" ");
	//		}
	//		sbuffer.append(docids[i]);
	//		sbuffer.append(" ");
	//		sbuffer.append(scores[i]);
	//		sbuffer.append('\n');
	//	}
		//System.out.println(sbuffer.toString());
	//	pw.write(sbuffer.toString());
	//	pw.flush();
		//pw.write("finished outputting\n");
	//}
	/**
	 * Starts the interactive query application.
	 * @param args the command line arguments.
	 */
	public static void main(String[] args) {
                
                args1=args;
                int len=args.length;
               // for(int o=0;o<len;o++)
               // {System.out.println("args is: "+args[o]);}
                SentenceRetreivalNew iq = new SentenceRetreivalNew();
		if (args.length == 0)
		{
			iq.processQueries(1.0);
		}
		else if (args.length == 1 && args[0].equals("--noverbose"))
		{
			iq.verbose = false;
			iq.processQueries(1.0);
		}
		else
		{
			iq.verbose = false;
			StringBuilder s = new StringBuilder();
			for(int i=0; i<args.length;i++)
			{
				s.append(args[i]);
				s.append(" ");
			}
			iq.processQuery("CMDLINE", s.toString(), 1.0);
		}	
	}

   
String finaldocs;
String content=new String();

    private void printer() throws IOException {
        MetaIndex meta2=index.getMetaIndex();
      //    System.out.println("the final docids are : ");
          for(int h:hp.keySet())
          {
           
       //       System.out.println(" h is: "+h);
            finaldocs=meta1.getItem("filename", h);
          //  System.out.println(finaldocs);
            FileReader fr1=new FileReader(finaldocs);
            BufferedReader read1=new BufferedReader(fr1);
           str789=read1.readLine();
            do
            {     
              content=content+" "+str789;
              str789="";
          } while((str789=read1.readLine())!=null);
          
    
    }
         System.out.println("\n "+content);
         content="";
         
         System.out.println("\n ");
    }
}
